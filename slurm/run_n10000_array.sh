#!/bin/bash
#SBATCH --partition=encore
#SBATCH --job-name=sim_n10000
#SBATCH --output=sim_n10000_%A_%a.out
#SBATCH --error=sim_n10000_%A_%a.err
#SBATCH --partition=encore
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-500

cd "$SLURM_SUBMIT_DIR" || exit 1

module load R

Rscript source/run_simulation_array_task.R 10000