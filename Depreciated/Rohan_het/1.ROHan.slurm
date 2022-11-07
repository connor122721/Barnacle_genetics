#!/usr/bin/env bash
#
#SBATCH -J rohan # A single job name for the array
#SBATCH --ntasks-per-node=10 # multi core
#SBATCH -N 1 # on one node
#SBATCH -t 1-00:00 # 1 day
#SBATCH --mem 100G
#SBATCH -o /scratch/csm6hg/barnacle/rohan/rohan.out # Standard output
#SBATCH -e /scratch/csm6hg/barnacle/rohan/rohan.err # Standard error
#SBATCH -p largemem
#SBATCH --account berglandlab_standard

# Modules
module load samtools
module load gsl
module load htslib
module load samtools
module load picard

# Working directory
wd="/scratch/csm6hg/barnacle"
cd /home/csm6hg/

# Get TS/TV ratio - using SnpSift
# java -jar /home/csm6hg/SNPEFF/SnpSift.jar tstv \
# ${wd}/split_pool/pool.vcf.gz
# Ts/Tv: merged=1.170; P9022=1.031, total=1.132

# go through each barnacle sample
for f in /scratch/csm6hg/barnacle/bam/*.sort.bam; do
# f="/scratch/csm6hg/barnacle/P9022_Bi03.bwa.sortbx.haploid.sort.bam"
# f="/scratch/csm6hg/barnacle/bam/merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.bam"
# Message
echo "ROHAN -> $f"

# Extract name for output
samp=$( echo ${f} | sed 's/.sort.bam//' )
echo ${samp}

# Sort and index
#samtools sort -@ 10 ${f} -o ${samp}_finalmap.sort.bam
samtools index -@ 10 ${f}

# Run rohan
rohan \
-t 10 \
--size 100000 \
--tstv 1.132 \
--auto ${wd}/chrom.500kb \
-o ${samp}.rohan \
${wd}/haploid_assembly_BUSCOmancur.fasta \
${f}

# Finish

done
