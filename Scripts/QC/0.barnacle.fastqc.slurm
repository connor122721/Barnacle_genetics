#!/usr/bin/env bash
#
#SBATCH -J fastqc # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH --cpus-per-task=2 # 10 cores
#SBATCH -N 1 # on one node
#SBATCH -t 1-00:00 # 1 day
#SBATCH --mem 100G
#SBATCH -o /scratch/csm6hg/barnacle/fastqc.out # Standard output
#SBATCH -e /scratch/csm6hg/barnacle/fastqc.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard

# Parameters
wd="/scratch/csm6hg/barnacle"
threads=2

# Collect quality metrics
module load fastqc

# Run fastqc
fastqc -t ${threads} \
${wd}/P9022_Bi03.bwa.sortbx.haploid.bam \
${wd}/merged_P6355_P8901_Bi02.bwa.sortbx.haploid.bam
