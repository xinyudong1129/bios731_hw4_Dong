
# Run one replication of the simulation study

suppressPackageStartupMessages({
  library(here)
})

source(here::here("source", "simulate_k_mixture_data.R"))
source(here::here("source", "gibbs_k_mixture.R"))
source(here::here("source", "variational_k_mixture.R"))

run_one_replication <- function(n,
                                sim_id,
                                mu_true = c(0, 5, 10, 20),
                                sigma2_prior = 100,
                                gibbs_n_iter = 10000,
                                gibbs_burn_in = 2000,
                                vi_max_iter = 1000,
                                vi_tol = 1e-8) {
  
  # reproducible per replication
  dat <- simulate_k_mixture_data(
    n = n,
    mu_true = mu_true,
    obs_var = 1,
    seed = 100000 + 10 * n + sim_id
  )
  
  y <- dat$y
  K <- length(mu_true)
  
  # Gibbs

  gibbs_time <- system.time({
    fit_gibbs <- gibbs_k_mixture(
      y = y,
      K = K,
      sigma2 = sigma2_prior,
      n_iter = gibbs_n_iter,
      burn_in = gibbs_burn_in,
      seed = 200000 + 10 * n + sim_id,
      save_output = FALSE
    )
  })
  
  gibbs_draws <- fit_gibbs$draws$mu_draws
  gibbs_draws_sorted <- t(apply(gibbs_draws, 1, sort))
  
  gibbs_mean <- colMeans(gibbs_draws_sorted)
  gibbs_lwr <- apply(gibbs_draws_sorted, 2, quantile, probs = 0.025)
  gibbs_upr <- apply(gibbs_draws_sorted, 2, quantile, probs = 0.975)
  gibbs_cover <- as.integer(mu_true >= gibbs_lwr & mu_true <= gibbs_upr)
  

  # VI

  vi_time <- system.time({
    fit_vi <- variational_k_mixture(
      y = y,
      K = K,
      sigma2 = sigma2_prior,
      max_iter = vi_max_iter,
      tol = vi_tol,
      seed = 300000 + 10 * n + sim_id,
      save_output = FALSE
    )
  })
  
  vi_mean <- sort(fit_vi$variational_params$m)
  vi_sd <- sqrt(fit_vi$variational_params$s2[order(fit_vi$variational_params$m)])
  vi_lwr <- vi_mean - 1.96 * vi_sd
  vi_upr <- vi_mean + 1.96 * vi_sd
  vi_cover <- as.integer(mu_true >= vi_lwr & mu_true <= vi_upr)
  
  # Output row-wise results

  out_gibbs <- data.frame(
    sim_id = sim_id,
    n = n,
    method = "Gibbs",
    component = paste0("mu_", seq_len(K)),
    mu_true = mu_true,
    estimate = gibbs_mean,
    lower = gibbs_lwr,
    upper = gibbs_upr,
    covered = gibbs_cover,
    elapsed_seconds = unname(gibbs_time["elapsed"])
  )
  
  out_vi <- data.frame(
    sim_id = sim_id,
    n = n,
    method = "VI",
    component = paste0("mu_", seq_len(K)),
    mu_true = mu_true,
    estimate = vi_mean,
    lower = vi_lwr,
    upper = vi_upr,
    covered = vi_cover,
    elapsed_seconds = unname(vi_time["elapsed"])
  )
  
  rbind(out_gibbs, out_vi)
}