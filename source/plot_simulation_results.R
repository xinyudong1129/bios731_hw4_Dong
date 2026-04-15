
# Plot simulation summaries with Monte Carlo SE bars

suppressPackageStartupMessages({
  library(here)
  library(ggplot2)
  library(dplyr)
})

plot_simulation_results <- function(summary_bias_cov, summary_time) {
  outdir <- here::here("results", "simulation_study", "summaries")
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  
  # Bias plot

  p_bias <- ggplot(summary_bias_cov,
                   aes(x = factor(n), y = bias, group = method, shape = method)) +
    geom_point(position = position_dodge(width = 0.35), size = 2.2) +
    geom_errorbar(
      aes(ymin = bias - 1.96 * mcse_bias,
          ymax = bias + 1.96 * mcse_bias),
      width = 0.15,
      position = position_dodge(width = 0.35)
    ) +
    facet_wrap(~ component, scales = "free_y") +
    labs(
      x = "Sample size",
      y = "Bias",
      title = "Bias of component mean estimates",
      subtitle = "Error bars are Monte Carlo standard errors"
    ) +
    theme_bw()
  
  ggsave(
    filename = here::here("results", "simulation_study", "summaries", "bias_plot.png"),
    plot = p_bias, width = 10, height = 6, dpi = 300
  )

  # Coverage plot

  p_cov <- ggplot(summary_bias_cov,
                  aes(x = factor(n), y = coverage, group = method, shape = method)) +
    geom_point(position = position_dodge(width = 0.35), size = 2.2) +
    geom_errorbar(
      aes(ymin = coverage - 1.96 * mcse_coverage,
          ymax = coverage + 1.96 * mcse_coverage),
      width = 0.15,
      position = position_dodge(width = 0.35)
    ) +
    geom_hline(yintercept = 0.95, linetype = 2) +
    facet_wrap(~ component) +
    labs(
      x = "Sample size",
      y = "Coverage",
      title = "Coverage of 95% intervals",
      subtitle = "Error bars are Monte Carlo standard errors"
    ) +
    theme_bw()
  
  ggsave(
    filename = here::here("results", "simulation_study", "summaries", "coverage_plot.png"),
    plot = p_cov, width = 10, height = 6, dpi = 300
  )
  

  # Time plot

  p_time <- ggplot(summary_time,
                   aes(x = factor(n), y = mean_time, group = method, shape = method)) +
    geom_point(position = position_dodge(width = 0.35), size = 2.2) +
    geom_errorbar(
      aes(ymin = mean_time - 1.96 * mcse_time,
          ymax = mean_time + 1.96 * mcse_time),
      width = 0.15,
      position = position_dodge(width = 0.35)
    ) +
    labs(
      x = "Sample size",
      y = "Mean elapsed time (seconds)",
      title = "Computation time comparison",
      subtitle = "Error bars are Monte Carlo standard errors"
    ) +
    theme_bw()
  
  ggsave(
    filename = here::here("results", "simulation_study", "summaries", "time_plot.png"),
    plot = p_time, width = 8, height = 5, dpi = 300
  )
  
  invisible(list(
    p_bias = p_bias,
    p_cov = p_cov,
    p_time = p_time
  ))
}