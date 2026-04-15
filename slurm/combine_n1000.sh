#!/bin/bash
#SBATCH --partition=encore
#SBATCH --job-name=combine_n1000
#SBATCH --output=combine_n1000_%j.out
#SBATCH --error=combine_n1000_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1

cd "$SLURM_SUBMIT_DIR" || exit 1
module load R

Rscript source/combine_simulation_results.R 1000