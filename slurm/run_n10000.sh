#!/bin/bash
#SBATCH --job-name=sim_n10000
#SBATCH --output=sim_n10000_%j.out
#SBATCH --error=sim_n10000_%j.err
#SBATCH --time=48:00:00
#SBATCH --mem=12G
#SBATCH --cpus-per-task=1

module load R
Rscript source/run_simulation_scenario.R 10000