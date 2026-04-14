
# CAVI for Bayesian K-mixture model

suppressPackageStartupMessages({
  library(here)
})

# Compute ELBO

compute_elbo_k_mixture <- function(y, r, m, s2, sigma2) {
  n <- length(y)
  K <- length(m)
  
  # E_q[log p(mu)]
  term_mu_prior <- sum(
    -0.5 * log(2 * pi * sigma2) -
      0.5 * (m^2 + s2) / sigma2
  )
  
  # E_q[log p(c)]
  term_c_prior <- -n * log(K)
  
  # E_q[log p(y | c, mu)]
  term_lik <- 0
  for (i in seq_len(n)) {
    for (k in seq_len(K)) {
      eq_sq <- y[i]^2 - 2 * y[i] * m[k] + (m[k]^2 + s2[k])
      term_lik <- term_lik +
        r[i, k] * (-0.5 * log(2 * pi) - 0.5 * eq_sq)
    }
  }
  
  # -E_q[log q(mu)] = entropy of normal factors
  term_entropy_mu <- sum(0.5 * log(2 * pi * exp(1) * s2))
  
  # -E_q[log q(c)] = categorical entropy
  eps <- 1e-12
  term_entropy_c <- -sum(r * log(pmax(r, eps)))
  
  elbo <- term_mu_prior + term_c_prior + term_lik +
    term_entropy_mu + term_entropy_c
  
  return(elbo)
}

# CAVI function

variational_k_mixture <- function(y,
                                  K,
                                  sigma2,
                                  max_iter = 1000,
                                  tol = 1e-8,
                                  seed = 123,
                                  init_m = NULL,
                                  init_s2 = NULL,
                                  init_r = NULL,
                                  save_output = TRUE) {
  set.seed(seed)
  
  if (!is.numeric(y)) stop("y must be numeric.")
  if (length(y) == 0) stop("y must be nonempty.")
  if (K < 1 || K != as.integer(K)) stop("K must be a positive integer.")
  if (sigma2 <= 0) stop("sigma2 must be positive.")
  
  n <- length(y)
  

  # Initialize variational parameters

  if (is.null(init_m)) {
    m <- rnorm(K, mean = 0, sd = sqrt(sigma2))
  } else {
    if (length(init_m) != K) stop("init_m must have length K.")
    m <- init_m
  }
  
  if (is.null(init_s2)) {
    s2 <- rep(sigma2, K)
  } else {
    if (length(init_s2) != K) stop("init_s2 must have length K.")
    if (any(init_s2 <= 0)) stop("init_s2 must be positive.")
    s2 <- init_s2
  }
  
  if (is.null(init_r)) {
    r <- matrix(runif(n * K), nrow = n, ncol = K)
    r <- r / rowSums(r)
  } else {
    if (!all(dim(init_r) == c(n, K))) stop("init_r must be an n x K matrix.")
    if (any(init_r < 0)) stop("init_r must be nonnegative.")
    r <- init_r / rowSums(init_r)
  }
  
  elbo_trace <- numeric(max_iter)
  converged <- FALSE
  

  # CAVI loop

  for (iter in seq_len(max_iter)) {
    

    # Update r_ik

    for (i in seq_len(n)) {
      log_rho <- y[i] * m - 0.5 * (m^2 + s2)
      log_rho <- log_rho - max(log_rho)  # numerical stability
      rho <- exp(log_rho)
      r[i, ] <- rho / sum(rho)
    }
    

    # Update q(mu_k) parameters

    for (k in seq_len(K)) {
      rk_sum <- sum(r[, k])
      rky_sum <- sum(r[, k] * y)
      
      s2[k] <- 1 / (1 / sigma2 + rk_sum)
      m[k]  <- s2[k] * rky_sum
    }
    

    # Compute ELBO

    elbo_trace[iter] <- compute_elbo_k_mixture(
      y = y,
      r = r,
      m = m,
      s2 = s2,
      sigma2 = sigma2
    )
    

    # Check convergence

    if (iter > 1) {
      if (abs(elbo_trace[iter] - elbo_trace[iter - 1]) < tol) {
        converged <- TRUE
        elbo_trace <- elbo_trace[seq_len(iter)]
        break
      }
    }
  }
  
  if (!converged) {
    elbo_trace <- elbo_trace[seq_len(max_iter)]
  }
  

  # Posterior summaries

  mu_summary <- data.frame(
    cluster = seq_len(K),
    post_mean = m,
    post_sd = sqrt(s2)
  )
  
  map_cluster <- apply(r, 1, which.max)
  
  cluster_summary <- data.frame(
    observation = seq_len(n),
    y = y,
    map_cluster = map_cluster,
    r
  )
  colnames(cluster_summary)[4:(3 + K)] <- paste0("cluster_", seq_len(K))
  
  elbo_summary <- data.frame(
    iteration = seq_along(elbo_trace),
    elbo = elbo_trace
  )
  
  results <- list(
    inputs = list(
      y = y,
      K = K,
      sigma2 = sigma2,
      max_iter = max_iter,
      tol = tol,
      seed = seed
    ),
    variational_params = list(
      m = m,
      s2 = s2,
      r = r
    ),
    summaries = list(
      mu_summary = mu_summary,
      cluster_summary = cluster_summary,
      elbo_summary = elbo_summary
    ),
    converged = converged
  )
  

  # Save outputs

  if (save_output) {
    dir.create(
      here::here("results", "variational_k_mixture"),
      recursive = TRUE,
      showWarnings = FALSE
    )
    
    write.csv(
      mu_summary,
      here::here("results", "variational_k_mixture", "mu_summary_vi.csv"),
      row.names = FALSE
    )
    
    write.csv(
      cluster_summary,
      here::here("results", "variational_k_mixture", "cluster_summary_vi.csv"),
      row.names = FALSE
    )
    
    write.csv(
      elbo_summary,
      here::here("results", "variational_k_mixture", "elbo_trace_vi.csv"),
      row.names = FALSE
    )
    
    saveRDS(
      results,
      here::here("results", "variational_k_mixture", "vi_results.rds")
    )
  }
  
  return(results)
}