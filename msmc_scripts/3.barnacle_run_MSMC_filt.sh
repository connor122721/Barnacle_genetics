#!/usr/bin/env bash
#SBATCH -J MSMC-barnacle # A single job name for the array
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH -t 1-00:00 # Running time of 1 day
#SBATCH --mem 100G # Memory request of 100GB
#SBATCH -o  /scratch/csm6hg/barnacle/Run.msmc.out # Standard output
#SBATCH -e  /scratch/csm6hg/barnacle/Run.msmc.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard

# Load Modules
module load anaconda/2020.11-py3.8
source activate msprime_env
module load bcftools

# Parameters
wd="/scratch/csm6hg/barnacle"
intervals=${wd}/chrom.500kb
threads=10

# Run MSMC independently
/project/berglandlab/connor/msmc2_linux64bit \
--fixedRecombination \
-t ${threads} \
-o ${wd}/pool.500kb.filtq35.fixr.msmc \
${wd}/split_pool/*.filtq35.hetsep

# Create combined hetsep files for each chromosome
while read chrom; do

	# Progress message
	echo ${chrom}

	# Combine all samples
	python /project/berglandlab/connor/msmc-tools/generate_multihetsep.py \
	${wd}/split_pool/*${chrom}.filtq35.vcf.gz > \
	${wd}/combined/pool.${chrom}.filtq35.hetsep

done < ${intervals}

# Run MSMC combined - pooled
/project/berglandlab/connor/msmc2_linux64bit \
-t ${threads} \
--skipAmbiguous \
--fixedRecombination \
-p 10*1+15*2 \
-I 0,1 \
-o ${wd}/combined.pool.500kb.filtq35.fixr.2segs.msmc \
${wd}/combined/pool*.filtq35.hetsep
