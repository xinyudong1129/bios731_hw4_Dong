#!/bin/bash
#SBATCH --partition=encore
#SBATCH --job-name=combine_n10000
#SBATCH --output=slurm/combine_n10000_%j.out
#SBATCH --error=slurm/combine_n10000_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1

module load R

cd /home/xdong63/BIOS731/hw4

Rscript source/combine_simulation_results.R 10000