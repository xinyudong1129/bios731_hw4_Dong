
# Simulate data from a K-component Gaussian mixture

simulate_k_mixture_data <- function(n,
                                    mu_true = c(0, 5, 10, 20),
                                    prob = NULL,
                                    obs_var = 1,
                                    seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  K <- length(mu_true)
  
  if (is.null(prob)) {
    prob <- rep(1 / K, K)
  }
  
  z <- sample.int(K, size = n, replace = TRUE, prob = prob)
  y <- rnorm(n, mean = mu_true[z], sd = sqrt(obs_var))
  
  list(
    y = y,
    z = z,
    mu_true = mu_true,
    prob = prob
  )
}