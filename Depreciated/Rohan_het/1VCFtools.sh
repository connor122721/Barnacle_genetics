#! /bin/bash
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=10G
#SBATCH --time=24:00:00
#SBATCH --partition=standard
#SBATCH --account=berglandlab
#SBATCH -o /scratch/csm6hg/daphnia_phylo/vcf/err/FinQCVCF.%A_%a.out # Standard output
#SBATCH -e /scratch/csm6hg/daphnia_phylo/vcf/err/FinQCVCF.%A_%a.err # Standard error

# This script will check various QC statistics from a raw VCF file

# Load Modules
module load vcftools
module load bcftools/1.9
module load tabix
module load htslib

# BGzip and tabix all shapeit.vcfs
for f in /scratch/csm6hg/barnacle/split_pool/*.vcf.gz; do

  gunzip $f

  # Bam file to use
	vcf=${f}

  # Extract name for new folder
	samp=$( echo ${vcf} |  sed 's/.gz//' )

  # Bgzip
  echo "Bgzip file -> $f"
  bgzip ${samp}

  # Tabix
  echo "Index file -> $f"
  tabix -p vcf \
  ${samp}.gz

done

# Creates list for all shapeit.vcf.gz files
ls -d /scratch/csm6hg/barnacle/split_pool/*.vcf.gz > \
/scratch/csm6hg/barnacle/split_pool/vcf.list

# Concatinate all shapeit.bcf files into common vcf
bcftools \
concat \
-f /scratch/csm6hg/barnacle/split_pool/vcf.list \
-Ov \
-l \
-o /scratch/csm6hg/barnacle/split_pool/pool.vcf

# Bgzip and tabix
bgzip /scratch/csm6hg/barnacle/split_pool/pool.vcf
tabix -p vcf /scratch/csm6hg/barnacle/split_pool/pool.vcf.gz

# Working folder is core folder where this pipeline is being run.
WORKING_FOLDER=/scratch/csm6hg/barnacle

# Move to working directory
cd $WORKING_FOLDER

# Survey quality of final VCF
analyses=("--depth" \
"--site-mean-depth" \
"--site-quality" \
"--site-pi" \
"--window-pi 10000 --window-pi-step 5000" \
"--het")

# For loop to run through 6 QC steps
for i in {0..5}

do

echo "Now processing" ${analyses[${i}]}

# Run VCFTools
vcftools \
--gzvcf split_pool/pool.vcf.gz \
`echo ${analyses[${i}]}` \
--out $WORKING_FOLDER/split_pool/pool

# Finish i
done

echo "VCF QC completed" $(date)
