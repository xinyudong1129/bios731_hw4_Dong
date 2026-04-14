
# Gibbs sampler for Bayesian K-mixture model

suppressPackageStartupMessages({
  library(here)
})


# Sample one draw from a categorical distribution

sample_categorical <- function(prob) {
  sample.int(n = length(prob), size = 1, prob = prob)
}


# Gibbs sampler function

gibbs_k_mixture <- function(y,
                            K,
                            sigma2,
                            n_iter = 5000,
                            burn_in = 1000,
                            init_mu = NULL,
                            init_c = NULL,
                            seed = 123,
                            save_output = TRUE) {
  
  set.seed(seed)
  
  if (!is.numeric(y)) stop("y must be numeric.")
  if (length(y) == 0) stop("y must be nonempty.")
  if (K < 1 || K != as.integer(K)) stop("K must be a positive integer.")
  if (sigma2 <= 0) stop("sigma2 must be positive.")
  if (n_iter <= burn_in) stop("n_iter must be greater than burn_in.")
  
  n <- length(y)
  

  # Initialize parameters

  if (is.null(init_mu)) {
    mu <- rnorm(K, mean = 0, sd = sqrt(sigma2))
  } else {
    if (length(init_mu) != K) stop("init_mu must have length K.")
    mu <- init_mu
  }
  
  if (is.null(init_c)) {
    c <- sample.int(K, size = n, replace = TRUE)
  } else {
    if (length(init_c) != n) stop("init_c must have length n.")
    if (any(!init_c %in% seq_len(K))) stop("init_c must only contain values 1,...,K.")
    c <- init_c
  }
  

  # Storage

  n_keep <- n_iter - burn_in
  
  mu_draws <- matrix(NA_real_, nrow = n_keep, ncol = K)
  c_draws  <- matrix(NA_integer_, nrow = n_keep, ncol = n)
  
  colnames(mu_draws) <- paste0("mu_", seq_len(K))
  colnames(c_draws)  <- paste0("obs_", seq_len(n))
  
  keep_idx <- 0L
  

  # Gibbs sampler

  for (iter in seq_len(n_iter)) {
    

    # Update c_i | y_i, mu

    for (i in seq_len(n)) {
      log_w <- -0.5 * (y[i] - mu)^2
      log_w <- log_w - max(log_w)   # numerical stability
      w <- exp(log_w)
      prob <- w / sum(w)
      
      c[i] <- sample_categorical(prob)
    }
    

    # Update mu_k | y, c

    for (k in seq_len(K)) {
      idx_k <- which(c == k)
      n_k <- length(idx_k)
      sum_y_k <- if (n_k > 0) sum(y[idx_k]) else 0
      
      post_var <- 1 / (n_k + 1 / sigma2)
      post_mean <- post_var * sum_y_k
      
      mu[k] <- rnorm(1, mean = post_mean, sd = sqrt(post_var))
    }
    

    # Save posterior draws

    if (iter > burn_in) {
      keep_idx <- keep_idx + 1L
      mu_draws[keep_idx, ] <- mu
      c_draws[keep_idx, ] <- c
    }
  }
  

  # Posterior summaries

  mu_summary <- data.frame(
    cluster = seq_len(K),
    post_mean = colMeans(mu_draws),
    post_sd = apply(mu_draws, 2, sd)
  )
  
  cluster_prob <- matrix(0, nrow = n, ncol = K)
  for (k in seq_len(K)) {
    cluster_prob[, k] <- colMeans(c_draws == k)
  }
  colnames(cluster_prob) <- paste0("cluster_", seq_len(K))
  
  map_cluster <- apply(cluster_prob, 1, which.max)
  
  cluster_summary <- data.frame(
    observation = seq_len(n),
    y = y,
    map_cluster = map_cluster,
    cluster_prob
  )
  
  results <- list(
    inputs = list(
      y = y,
      K = K,
      sigma2 = sigma2,
      n_iter = n_iter,
      burn_in = burn_in,
      seed = seed
    ),
    draws = list(
      mu_draws = mu_draws,
      c_draws = c_draws
    ),
    summaries = list(
      mu_summary = mu_summary,
      cluster_summary = cluster_summary
    )
  )
  

  # Save outputs using here::here()

  if (save_output) {
    dir.create(here::here("results", "gibbs_k_mixture"),
               recursive = TRUE, showWarnings = FALSE)
    
    write.csv(
      mu_summary,
      here::here("results", "gibbs_k_mixture", "mu_summary.csv"),
      row.names = FALSE
    )
    
    write.csv(
      cluster_summary,
      here::here("results", "gibbs_k_mixture", "cluster_summary.csv"),
      row.names = FALSE
    )
    
    saveRDS(
      results,
      here::here("results", "gibbs_k_mixture", "gibbs_results.rds")
    )
  }
  
  return(results)
}