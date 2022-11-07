#!/usr/bin/env bash
#
#SBATCH -J bamqc # A single job name for the array
#SBATCH --ntasks-per-node=1 # multi core
#SBATCH -N 1 # on one node
#SBATCH -t 3-00:00 # 5 hours
#SBATCH --mem 20G
#SBATCH -o /scratch/csm6hg/barnacle/err/bam.out # Standard output
#SBATCH -e /scratch/csm6hg/barnacle/err/bam.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard

# Run QC on all bams

# Move to directory
cd /scratch/csm6hg/barnacle

# BamQC executable
bamqc="/home/csm6hg/BamQC/bin/bamqc"

# Run program on all bams
${bamqc} *.sort.bam \
--outdir bamqcout
