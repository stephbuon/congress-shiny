#!/bin/bash
#SBATCH -J export_clean_congress_tokens
#SBATCH -o export_clean_congress_tokens.out
#SBATCH -p standard-mem-s,standard-mem-m,standard-mem-l,medium-mem-1-s,medium-mem-2,medium-mem-1-m,high-mem-1,high-mem-2
#SBATCH --mem=100G
#SBATCH --exclusive
#SBATCH --ntasks-per-node=25

module purge
module load r

Rscript export_clean_congress_tokens.R --cores ${SLURM_NTASKS}
