
# Problem 3: Fit Gibbs sampler and VI to Old Faithful data

suppressPackageStartupMessages({
  library(here)
  library(coda)
})

source(here::here("source", "gibbs_k_mixture.R"))
source(here::here("source", "variational_k_mixture.R"))

# Helper: order component means within each Gibbs draw
# This helps make cross-chain diagnostics more interpretable.

order_mu_draws <- function(mu_draws) {
  t(apply(mu_draws, 1, sort))
}


# Helper: back-transform standardized means

backtransform_means <- function(mu_std, center, scale) {
  mu_std * scale + center
}


# Main Problem 3 analysis function

fit_faithful_problem3 <- function(K = 2,
                                  sigma2 = 25,
                                  gibbs_n_iter = 10000,
                                  gibbs_burn_in = 2000,
                                  vi_max_iter = 2000,
                                  vi_tol = 1e-8,
                                  n_chains = 4,
                                  seeds = c(101, 202, 303, 404),
                                  save_output = TRUE) {
  
  if (length(seeds) < n_chains) {
    stop("Length of seeds must be at least n_chains.")
  }
  
 
  # Load and standardize data

  y_raw <- datasets::faithful$waiting
  y_std_mat <- scale(y_raw)
  y <- as.numeric(y_std_mat)
  
  y_center <- attr(y_std_mat, "scaled:center")
  y_scale  <- attr(y_std_mat, "scaled:scale")
  
  n <- length(y)
  

  # Create output directory

  outdir <- here::here("results", "problem3_faithful")
  if (save_output) {
    dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  }
  

  # Fit VI

  vi_time <- system.time({
    fit_vi <- variational_k_mixture(
      y = y,
      K = K,
      sigma2 = sigma2,
      max_iter = vi_max_iter,
      tol = vi_tol,
      seed = seeds[1],
      save_output = FALSE
    )
  })
  
  vi_mu_std <- sort(fit_vi$variational_params$m)
  vi_mu_raw <- backtransform_means(vi_mu_std, y_center, y_scale)
  
 
  # Fit Gibbs sampler with multiple chains
 
  gibbs_fits <- vector("list", n_chains)
  gibbs_times <- vector("list", n_chains)
  ordered_chain_draws <- vector("list", n_chains)
  
  # dispersed initializations
  init_mu_list <- list(
    c(-2, 2),
    c(-1, 1),
    c(-2.5, 0.5),
    c(-0.5, 2.5)
  )
  
  for (ch in seq_len(n_chains)) {
    gibbs_times[[ch]] <- system.time({
      gibbs_fits[[ch]] <- gibbs_k_mixture(
        y = y,
        K = K,
        sigma2 = sigma2,
        n_iter = gibbs_n_iter,
        burn_in = gibbs_burn_in,
        init_mu = init_mu_list[[ch]],
        seed = seeds[ch],
        save_output = FALSE
      )
    })
    
    ordered_chain_draws[[ch]] <- order_mu_draws(gibbs_fits[[ch]]$draws$mu_draws)
    colnames(ordered_chain_draws[[ch]]) <- paste0("mu_", seq_len(K))
  }
  
  # combine posterior draws across chains
  all_ordered_draws <- do.call(rbind, ordered_chain_draws)
  
  gibbs_mu_std <- colMeans(all_ordered_draws)
  gibbs_mu_raw <- backtransform_means(gibbs_mu_std, y_center, y_scale)
  
 
  # coda objects for diagnostics
 
  mcmc_list <- coda::mcmc.list(
    lapply(ordered_chain_draws, coda::mcmc)
  )
  
  ess <- coda::effectiveSize(mcmc_list)
  gelman <- coda::gelman.diag(mcmc_list, autoburnin = FALSE, multivariate = FALSE)
  
  
  # Timing summary

  timing_summary <- data.frame(
    method = c("VI", paste0("Gibbs_chain_", seq_len(n_chains)), "Gibbs_total"),
    elapsed_seconds = c(
      unname(vi_time["elapsed"]),
      sapply(gibbs_times, function(x) unname(x["elapsed"])),
      sum(sapply(gibbs_times, function(x) unname(x["elapsed"])))
    )
  )
  
  
  # Parameter comparison table
 
  comparison_summary <- data.frame(
    component = paste0("mu_", seq_len(K)),
    gibbs_mean_std = gibbs_mu_std,
    vi_mean_std = vi_mu_std,
    gibbs_mean_raw = gibbs_mu_raw,
    vi_mean_raw = vi_mu_raw
  )
  

  # ESS summary

  ess_summary <- data.frame(
    parameter = names(ess),
    ess = as.numeric(ess)
  )
  
  # Gelman summary

  gelman_summary <- data.frame(
    parameter = rownames(gelman$psrf),
    point_estimate = gelman$psrf[, 1],
    upper_CI = gelman$psrf[, 2]
  )
  
 
  # ELBO summary from VI
 
  elbo_summary <- fit_vi$summaries$elbo_summary
  
  # Save diagnostic plots

  if (save_output) {
    
    # Trace plots
    png(here::here("results", "problem3_faithful", "gibbs_traceplots.png"),
        width = 1200, height = 800)
    plot(mcmc_list)
    dev.off()
    
    # Autocorrelation plots
    png(here::here("results", "problem3_faithful", "gibbs_acfplots.png"),
        width = 1200, height = 800)
    autocorr.plot(mcmc_list)
    dev.off()
    
    # Gelman plot
    png(here::here("results", "problem3_faithful", "gibbs_gelmanplot.png"),
        width = 1000, height = 700)
    gelman.plot(mcmc_list, autoburnin = FALSE)
    dev.off()
    
    # VI ELBO plot
    png(here::here("results", "problem3_faithful", "vi_elbo_plot.png"),
        width = 1000, height = 700)
    plot(
      elbo_summary$iteration, elbo_summary$elbo,
      type = "l",
      xlab = "Iteration",
      ylab = "ELBO",
      main = "VI ELBO Trace"
    )
    dev.off()
    
    # Data histogram with estimated means
    png(here::here("results", "problem3_faithful", "faithful_histogram_means.png"),
        width = 1000, height = 700)
    hist(
      y_raw,
      breaks = 30,
      main = "Old Faithful Waiting Times with Estimated Component Means",
      xlab = "Waiting time",
      col = "grey90",
      border = "white"
    )
    abline(v = gibbs_mu_raw, lwd = 2, lty = 1)
    abline(v = vi_mu_raw, lwd = 2, lty = 2)
    legend(
      "topright",
      legend = c("Gibbs posterior means", "VI means"),
      lty = c(1, 2),
      lwd = 2,
      bty = "n"
    )
    dev.off()
    
    # Save tables
    write.csv(
      timing_summary,
      here::here("results", "problem3_faithful", "timing_summary.csv"),
      row.names = FALSE
    )
    
    write.csv(
      comparison_summary,
      here::here("results", "problem3_faithful", "parameter_comparison.csv"),
      row.names = FALSE
    )
    
    write.csv(
      ess_summary,
      here::here("results", "problem3_faithful", "ess_summary.csv"),
      row.names = FALSE
    )
    
    write.csv(
      gelman_summary,
      here::here("results", "problem3_faithful", "gelman_summary.csv"),
      row.names = FALSE
    )
    
    write.csv(
      elbo_summary,
      here::here("results", "problem3_faithful", "vi_elbo_summary.csv"),
      row.names = FALSE
    )
    
    saveRDS(
      list(
        y_raw = y_raw,
        y_std = y,
        fit_vi = fit_vi,
        gibbs_fits = gibbs_fits,
        ordered_chain_draws = ordered_chain_draws,
        timing_summary = timing_summary,
        comparison_summary = comparison_summary,
        ess_summary = ess_summary,
        gelman_summary = gelman_summary
      ),
      here::here("results", "problem3_faithful", "problem3_results.rds")
    )
  }
  
  return(list(
    y_raw = y_raw,
    y_std = y,
    center = y_center,
    scale = y_scale,
    fit_vi = fit_vi,
    gibbs_fits = gibbs_fits,
    ordered_chain_draws = ordered_chain_draws,
    timing_summary = timing_summary,
    comparison_summary = comparison_summary,
    ess_summary = ess_summary,
    gelman_summary = gelman_summary
  ))
}