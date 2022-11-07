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

# For loop through individual bams
for file in ${wd}/*.haploid.sort.bam; do

  # Progress me
	echo "Processing individual:" ${file}

	# Bam file to use
	bam=${file}

  # Extract name for new folder
	samp=$( echo ${bam} | rev | cut -d '/' -f1 | rev )

  # Run MSMC independently
  /project/berglandlab/connor/msmc2_linux64bit \
  -t ${threads} \
  -o ${wd}/${samp%.*}.500kb.msmc \
  ${wd}/split_${samp%.*}/${samp%.*}*.hetsep

  # Run MSMC independently - shorter time segment
  /project/berglandlab/connor/msmc2_linux64bit \
  -t ${threads} \
  -p 1*2+16*1+1*2 \
  -o ${wd}/${samp%.*}.500kb.18segs.msmc \
  ${wd}/split_${samp%.*}/${samp%.*}*.hetsep

done

# Create combined hetsep files for each chromosome
while read chrom; do

	# Progress message
	echo ${chrom}

	# Combine all samples
	python /project/berglandlab/connor/msmc-tools/generate_multihetsep.py \
	${wd}/split_merged*/*${chrom}.vcf.gz \
	${wd}/split_P9022*/*${chrom}.vcf.gz > \
	${wd}/combined/combined.${chrom}.hetsep

done < ${intervals}

# Run MSMC combined - split
/project/berglandlab/connor/msmc2_linux64bit \
-t ${threads} \
--skipAmbiguous \
-I 0-2,0-3,1-2,1-3 \
-o ${wd}/combined.split.500kb.msmc \
${wd}/combined/*.hetsep

# Run MSMC combined - merged
/project/berglandlab/connor/msmc2_linux64bit \
-t ${threads} \
--skipAmbiguous \
-I 0,1 \
-o ${wd}/combined.merged.500kb.msmc \
${wd}/combined/*.hetsep

# Run MSMC combined - P9022
/project/berglandlab/connor/msmc2_linux64bit \
-t ${threads} \
--skipAmbiguous \
-I 2,3 \
-o ${wd}/combined.P9022.500kb.msmc \
${wd}/combined/*.hetsep

# Combine coalescent files
/project/berglandlab/connor/msmc-tools/combineCrossCoal.py \
${wd}/combined.merged.500kb.msmc.final.txt \
${wd}/combined.P9022.500kb.msmc.final.txt \
${wd}/combined.split.500kb.msmc.final.txt > \
${wd}/combined.msmc.final.txt
