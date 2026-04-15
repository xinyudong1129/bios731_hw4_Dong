
suppressPackageStartupMessages({
  library(here)
})

source(here::here("source", "run_one_replication.R"))

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Usage: Rscript source/run_simulation_array_task.R <n>")
}

n <- as.integer(args[1])

# Slurm array task ID = simulation replication ID
sim_id <- as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))

if (is.na(sim_id) || sim_id < 1) {
  stop("SLURM_ARRAY_TASK_ID is missing or invalid.")
}

outdir <- here::here("results", "simulation_study", paste0("n_", n), "reps")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

outfile_csv <- here::here(
  "results", "simulation_study", paste0("n_", n), "reps",
  paste0("sim_", sim_id, ".csv")
)

outfile_rds <- here::here(
  "results", "simulation_study", paste0("n_", n), "reps",
  paste0("sim_", sim_id, ".rds")
)

# Skip if already completed
if (file.exists(outfile_rds)) {
  cat("Replication", sim_id, "for n =", n, "already exists. Skipping.\n")
  quit(save = "no", status = 0)
}

cat("Running replication", sim_id, "for n =", n, "\n")

res <- run_one_replication(
  n = n,
  sim_id = sim_id,
  mu_true = c(0, 5, 10, 20),
  sigma2_prior = 100,
  gibbs_n_iter = 10000,
  gibbs_burn_in = 2000,
  vi_max_iter = 1000,
  vi_tol = 1e-8
)

saveRDS(res, outfile_rds)
write.csv(res, outfile_csv, row.names = FALSE)

cat("Finished replication", sim_id, "for n =", n, "\n")