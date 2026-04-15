suppressPackageStartupMessages({
  library(here)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Usage: Rscript source/combine_simulation_results.R <n>")
}

n <- as.integer(args[1])

rep_dir <- here::here("results", "simulation_study", paste0("n_", n), "reps")
out_dir <- here::here("results", "simulation_study", paste0("n_", n), "combined")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

files <- list.files(rep_dir, pattern = "^sim_[0-9]+\\.rds$", full.names = TRUE)

if (length(files) == 0) {
  stop("No replication files found in: ", rep_dir)
}

files <- files[order(files)]

all_results <- do.call(
  rbind,
  lapply(files, readRDS)
)

saveRDS(
  all_results,
  file = here::here("results", "simulation_study", paste0("n_", n), "combined", "scenario_results.rds")
)

write.csv(
  all_results,
  file = here::here("results", "simulation_study", paste0("n_", n), "combined", "scenario_results.csv"),
  row.names = FALSE
)

cat("Combined", length(files), "replications for n =", n, "\n")