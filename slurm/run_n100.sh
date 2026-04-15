#!/bin/bash
#SBATCH --job-name=sim_n100
#SBATCH --output=sim_n100_%j.out
#SBATCH --error=sim_n100_%j.err
#SBATCH --time=12:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

module load R
Rscript source/run_simulation_scenario.R 100