#!/usr/bin/env bash
#SBATCH -J MSMC-barnacle # A single job name for the array
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 0-01:00 # Running time of 1 hour
#SBATCH --mem 10G # Memory request of 100GB
#SBATCH -o  /scratch/csm6hg/barnacle/err/run.%A_%a.out # Standard output
#SBATCH -e  /scratch/csm6hg/barnacle/err/run.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard

# Load Modules
module load anaconda/2020.11-py3.8
source activate msprime_env
module load bcftools

# Parameters
wd="/scratch/csm6hg/barnacle"
ref=${wd}/haploid_assembly_BUSCOmancur.fasta
threads=1

# Chromosome file
intervals=${wd}/chrom.500kb

# Chromosomes to analyze (1:461)
chrom=`sed -n ${SLURM_ARRAY_TASK_ID}p $intervals`
#chrom=Bi03_p1mp_000003F

# Create pooled sample VCF
bcftools mpileup \
--threads ${threads} \
-q 35 -Q 35 \
-r ${chrom} \
-f ${ref} \
${wd}/*.haploid.sort.bam | \
bcftools call \
-c \
-V indels | \
/project/berglandlab/connor/msmc-tools/bamCaller.py 15 \
${wd}/split_pool/pool.${chrom}.filtq35.mask.bed.gz | bgzip > \
${wd}/split_pool/pool.${chrom}.filtq35.vcf.gz

# Run python input conversion script
python /project/berglandlab/connor/msmc-tools/generate_multihetsep.py \
--mask=${wd}/split_pool/pool.${chrom}.filtq35.mask.bed.gz \
${wd}/split_pool/pool.${chrom}.filtq35.vcf.gz > \
${wd}/split_pool/pool.${chrom}.filtq35.hetsep
