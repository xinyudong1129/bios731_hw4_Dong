#!/bin/bash
#SBATCH --job-name=sim_n1000
#SBATCH --output=sim_n1000_%j.out
#SBATCH --error=sim_n1000_%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

module load R
Rscript source/run_simulation_scenario.R 1000