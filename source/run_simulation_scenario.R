
# Run one simulation scenario for a given sample size n
# Usage:
#   Rscript source/run_simulation_scenario.R 100

suppressPackageStartupMessages({
  library(here)
})

source(here::here("source", "run_one_replication.R"))

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("Please provide n as a command-line argument.")
}

n <- as.integer(args[1])

nsim <- 500
mu_true <- c(0, 5, 10, 20)

outdir <- here::here("results", "simulation_study", paste0("n_", n))
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

all_results <- vector("list", nsim)

for (s in seq_len(nsim)) {
  cat("Running n =", n, "simulation", s, "of", nsim, "\n")
  all_results[[s]] <- run_one_replication(
    n = n,
    sim_id = s,
    mu_true = mu_true,
    sigma2_prior = 100,
    gibbs_n_iter = 10000,
    gibbs_burn_in = 2000,
    vi_max_iter = 1000,
    vi_tol = 1e-8
  )
}

scenario_results <- do.call(rbind, all_results)

write.csv(
  scenario_results,
  file = here::here("results", "simulation_study", paste0("n_", n), "scenario_results.csv"),
  row.names = FALSE
)

saveRDS(
  scenario_results,
  file = here::here("results", "simulation_study", paste0("n_", n), "scenario_results.rds")
)