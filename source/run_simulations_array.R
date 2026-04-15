
suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

# Parse arguments

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 4) {
  stop("Usage: Rscript simulations/run_simulations_array.R <n> <task_id> <chunk_size> <nsim_total>")
}

n          <- as.integer(args[1])
task_id    <- as.integer(args[2])
chunk_size <- as.integer(args[3])
nsim_total <- as.integer(args[4])

start_sim <- (task_id - 1L) * chunk_size + 1L
end_sim   <- min(task_id * chunk_size, nsim_total)

cat("========================================\n")
cat("Task:", task_id, "\n")
cat("Simulations:", start_sim, "to", end_sim, "\n")
cat("n =", n, "\n")
cat("Project root:", here::here(), "\n")
cat("========================================\n")

source(here::here("source", "simulate_k_mixture_data.R"))
source(here::here("source", "gibbs_k_mixture.R"))
source(here::here("source", "variational_k_mixture.R"))
source(here::here("source", "run_one_replication.R"))
source(here::here("source", "run_simulation_scenario.R"))


# Create output folders

dir.create(here::here("results"), showWarnings = FALSE)
dir.create(here::here("logs"), showWarnings = FALSE)

# Run simulations

sim_ids <- start_sim:end_sim
results_list <- vector("list", length(sim_ids))

for (i in seq_along(sim_ids)) {
  
  sim_id <- sim_ids[i]
  
  if (sim_id %% 10 == 0 || sim_id == start_sim) {
    cat("Running simulation", sim_id, "of", nsim_total, "\n")
    flush.console()
  }
  
  set.seed(100000 + sim_id)
  
  results_list[[i]] <- tryCatch(
    {
      out <- run_one_replication(n = n)
      
      if (is.data.frame(out)) {
        out$sim <- sim_id
        out$n   <- n
        out
      } else {
        tibble(sim = sim_id, n = n, result = out)
      }
    },
    error = function(e) {
      tibble(
        sim = sim_id,
        n = n,
        error = conditionMessage(e)
      )
    }
  )
}

results_df <- bind_rows(results_list)

# Save partial results

outfile <- here::here(
  "results",
  paste0("partial_n", n, "_task", task_id, ".rds")
)

saveRDS(results_df, outfile)

cat("Saved:", outfile, "\n")
cat("Rows:", nrow(results_df), "\n")