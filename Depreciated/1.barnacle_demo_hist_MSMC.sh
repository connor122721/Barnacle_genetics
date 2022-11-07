#!/usr/bin/env bash
#SBATCH -J MSMC-barnacle # A single job name for the array
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 0-01:00 # Running time of 1 hour
#SBATCH --mem 30G # Memory request of 100GB
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

# For loop through individual bams
for file in ${wd}/*.haploid.sort.bam; do

  # Progress me
	echo "Processing individual:" ${file}

	# Bam file to use
	bam=${file}

	# Extract name for new folder
	samp=$( echo ${bam} | rev | cut -d '/' -f1 | rev )

	# Chromosome file
	intervals=${wd}/chrom.500kb

	# Chromosomes to analyze (1:461)
	chrom=`sed -n ${SLURM_ARRAY_TASK_ID}p $intervals`

	# Create output folders
	if [[ -d "${wd}/split_${samp%.*}/" ]]
	then
		echo "Working tmp folder exist"
		echo "lets move on"
		date
	else
		echo "Folder doesnt exist. Let us fix that."
		mkdir ${wd}/split_${samp%.*}/
		date
	fi

	# Create single sample VCF
	bcftools mpileup \
	--threads ${threads} \
	-q 20 -Q 20 -C 50 \
	-r ${chrom} \
	-f ${ref} \
	${bam} | \
	bcftools call \
	-c \
	-V indels | \
	/project/berglandlab/connor/msmc-tools/bamCaller.py 10 \
	${wd}/split_${samp%.*}/${samp%.*}.${chrom}.mask.bed.gz | gzip -c > \
	${wd}/split_${samp%.*}/${samp%.*}.${chrom}.vcf.gz

	# Run python input conversion script
	python /project/berglandlab/connor/msmc-tools/generate_multihetsep.py \
	--mask=${wd}/split_${samp%.*}/${samp%.*}.${chrom}.mask.bed.gz \
	${wd}/split_${samp%.*}/${samp%.*}.${chrom}.vcf.gz > \
	${wd}/split_${samp%.*}/${samp%.*}.${chrom}.hetsep

done
