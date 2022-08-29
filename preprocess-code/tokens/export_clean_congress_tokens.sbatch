#!/bin/bash
#SBATCH -J tokenize_data
#SBATCH -o tokenize_data.out
#SBATCH -p standard-mem-s,standard-mem-m,standard-mem-l,medium-mem-1-s,medium-mem-2,medium-mem-1-m,high-mem-1,high-mem-2
#SBATCH --mem=100G

module purge
module load r

Rscript tokenize_data.R