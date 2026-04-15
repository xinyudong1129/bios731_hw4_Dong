# BIOS 731 Homework 4

This repository contains my solutions for **Homework 4 in BIOS 731: Bayesian Inference for Mixture Models**.

The homework includes:

- Gibbs sampler derivation and implementation  
- Variational inference derivation and implementation  
- Application to the Old Faithful waiting times data  
- A cluster-based simulation study comparing Gibbs sampling and variational Bayes (via HPC)

---

# Repository structure

## source/

This folder contains the main functions and scripts used across all problems.

- **simulate_k_mixture_data.R**  
  Generates data from a Gaussian mixture model.

- **run_one_replication.R**  
  Runs a single simulation replicate (data generation + model fitting).

- **run_simulation_scenario.R**  
  Runs a full simulation scenario for a fixed sample size.

- **run_simulations_array.R**  
  Main script used for HPC array jobs. Each task runs a subset of simulations.

- **combine_results.R**  
  Combines partial simulation outputs from array jobs into a single dataset.

- **summarize_simulation_results.R**  
  Computes summary statistics (bias, coverage, MCSE, etc.).

- **plot_simulation_results.R**  
  Generates plots for simulation summaries.

- **gibbs_k_mixture.R**  
  Implements the Gibbs sampler for the Bayesian Gaussian mixture model.

- **variational_k_mixture.R**  
  Implements coordinate ascent variational inference (CAVI).

- **fit_faithful_problem3.R**  
  Runs Gibbs and VI on the Old Faithful dataset.

---

## analysis/

This folder contains the final report and analysis.

- **homework_4_final_report_Xinyu_Dong.Rmd**  
  Main R Markdown file used to generate the final report.

- **homework_4_final_report_Xinyu_Dong.pdf**   
  Final compiled report for submission.

---

## slurm/

This folder contains scripts used to run simulations on the **Emory HPC cluster**.

- **run_n100.sh, run_n1000.sh, run_n10000.sh**  
  Single-job simulation scripts.

- **run_n10000_array.sh**  
  Slurm array job script for large-scale simulations.

- **submit_all.sh**  
  Helper script to submit multiple jobs.

---

## results/

This folder stores simulation outputs.

- **partial_n*_task*.rds**  
  Partial outputs from individual array tasks.

- **combined_n*.rds**  
  Combined simulation results after aggregation.

- **.csv / .png files**  
  Summary tables and plots used in the report.

---

## Project file

- **.Rproj file**  
  RStudio project file for reproducibility and consistent paths.

---

# Recommended workflow

## Problem 1 and Problem 2

The Gibbs sampler and variational inference methods are implemented in:

```r
source/01_gibbs_sampler.r
source/02_variational_mixture.r
```

Their derivations and explanations are included in:
analysis/homework_4_final_report_Xinyu_Dong.Rmd

## Problem 3: Old Faithful analysis

Step 1
Run the script:

source("source/fit_faithful_problem3.R")

This fits the Gibbs sampler and variational Bayes to the Old Faithful waiting times data and saves the results to the results/ folder as .rds objects.

Step 2
Open and run the corresponding section of:

analysis/homework_4_final_report_Xinyu_Dong.Rmd

This file loads the saved results, generates trace plots and density plots, and compares Gibbs sampling with variational inference.

## Problem 4: Cluster simulation study

Step 1
Upload the project to the HPC cluster:

scp -r your_project xdong63@clogin01.sph.emory.edu:~

Then log in:

ssh xdong63@clogin01.sph.emory.edu

Step 2
Submit the simulation jobs using Slurm array:

cd "BIOS 731 homework 4"
sbatch slurm/run_n10000_array.sh

Each array task runs a subset of simulations using:

Rscript source/run_simulations_array.R n task_id chunk_size nsim_total

Each task generates simulated data, fits the model, and saves partial results to:

results/partial_n{n}_taskX.rds

Step 3
Monitor progress on the cluster:

squeue -u xdong63
squeue -r -j <JOBID>

You can also check how many results have completed:

ls results | grep partial_n10000_task | wc -l

Step 4
After all jobs finish, combine the results:

module load R
Rscript source/combine_results.R 10000

This creates:

results/combined_n10000.rds

Step 5
Analyze the combined simulation results:

source("source/summarize_simulation_results.R")
source("source/plot_simulation_results.R")

This computes bias, coverage, Monte Carlo standard errors, and produces summary plots.

Step 6
Open and knit the final report:

analysis/homework_4_final_report_Xinyu_Dong.Rmd

This file summarizes the simulation study results and includes all figures and interpretations.
