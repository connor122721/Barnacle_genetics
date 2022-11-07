#!/usr/bin/env bash
#
#SBATCH -J samtools # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH --cpus-per-task=10 # 10 cores
#SBATCH -N 1 # on one node
#SBATCH -t 1-00:00 # 1 day
#SBATCH --mem 120G
#SBATCH -o /scratch/csm6hg/barnacle/samtools.out # Standard output
#SBATCH -e /scratch/csm6hg/barnacle/samtools.err # Standard error
#SBATCH -p largemem
#SBATCH --account berglandlab_standard

# Parameters
wd="/scratch/csm6hg/barnacle"
threads=10

# Collect quality metrics
module load samtools

# Run fastqc
samtools sort -@ ${threads} ${wd}/merged_P6355_P8901_Bi02.bwa.sortbx.haploid.bam \
-o ${wd}/merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.bam

samtools index -@ ${threads} \
${wd}/merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.bam

samtools sort -@ ${threads} \
${wd}/P9022_Bi03.bwa.sortbx.haploid.bam \
-o ${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.bam

samtools index -@ ${threads} \
${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.bam
