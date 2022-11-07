#!/usr/bin/env bash
#
#SBATCH -J barnacle # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH --cpus-per-task=10 # 10 cores
#SBATCH -N 1 # on one node
#SBATCH -t 1-00:00 # 1 day
#SBATCH --mem 100G
#SBATCH -o /scratch/csm6hg/barnacle/run.out # Standard output
#SBATCH -e /scratch/csm6hg/barnacle/run.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard

# Parameters
wd="/scratch/csm6hg/barnacle"
bam=${wd}/P9022_Bi03.bwa.sortbx.haploid.bam
ref=${wd}/haploid_assembly_BUSCOmancur.fasta
threads=10

# Load modules
module load samtools

# Index bam file
samtools sort \
-@ ${threads} \
${bam} \
-o P9022_Bi03.bwa.sortbx.haploid.sort.bam

# Collect quality metrics
module load fastqc

# Run fastqc
fastqc -t ${threads}\
${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.bam

# Load modules
module load samtools/1.10
module load bcftools/1.9
module load htslib/1.9
module load psmc/0.6.5
module load gnuplot/5.2.2

# Convert BAM to VCF
bcftools mpileup ${bam} -f ${ref} --threads ${threads} | \
bcftools call --threads ${threads} -cv -Ov -o ${wd}/P9022_Bi03.bwa.sortbx.haploid.vcf

# sort
bcftools sort ${wd}/P9022_Bi03.bwa.sortbx.haploid.vcf \
-o ${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.vcf

# Bgzip and tabix
bgzip -@ ${threads} ${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.vcf
tabix -p vcf ${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.vcf.gz

vcfutils.pl vcf2fq \
${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.vcf.gz \
-d 10 -D 100 -Q 30 | \
gzip > P9022_Bi03.bwa.sortbx.haploid.sort.fq.gz
