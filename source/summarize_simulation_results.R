
# Summarize simulation results across scenarios

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
})

summarize_simulation_results <- function() {
  n_vals <- c(100, 1000, 10000)
  
  res_list <- lapply(n_vals, function(n) {
    read.csv(
      here::here("results", "simulation_study", paste0("n_", n), "combined", "scenario_results.csv")
    )
  })
  
  dat <- bind_rows(res_list)
  
  dat <- dat %>%
    mutate(
      error = estimate - mu_true
    )
  
  summary_bias_cov <- dat %>%
    group_by(n, method, component, mu_true) %>%
    summarise(
      nsim = n(),
      mean_estimate = mean(estimate),
      bias = mean(error),
      mcse_bias = sd(error) / sqrt(n()),
      coverage = mean(covered),
      mcse_coverage = sqrt(coverage * (1 - coverage) / n()),
      .groups = "drop"
    )
  
  summary_time <- dat %>%
    group_by(n, method, sim_id) %>%
    summarise(
      elapsed_seconds = first(elapsed_seconds),
      .groups = "drop"
    ) %>%
    group_by(n, method) %>%
    summarise(
      nsim = n(),
      mean_time = mean(elapsed_seconds),
      mcse_time = sd(elapsed_seconds) / sqrt(n()),
      .groups = "drop"
    )
  
  outdir <- here::here("results", "simulation_study", "summaries")
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  
  write.csv(summary_bias_cov,
            here::here("results", "simulation_study", "summaries", "summary_bias_coverage.csv"),
            row.names = FALSE)
  
  write.csv(summary_time,
            here::here("results", "simulation_study", "summaries", "summary_time.csv"),
            row.names = FALSE)
  
  list(
    raw = dat,
    summary_bias_cov = summary_bias_cov,
    summary_time = summary_time
  )
}