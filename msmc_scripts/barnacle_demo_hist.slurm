#!/usr/bin/env bash
#
#SBATCH -J smcpp # A single job name for the array
#SBATCH --ntasks-per-node=5 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 0-10:00 # 10 hours
#SBATCH --mem 50G
#SBATCH -o //smcpp.out # Standard output
#SBATCH -e //smcpp.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard

# SLURM_ARRAY_TASK_ID=1

# Load SMC++ modules
source /home/csm6hg/smcpp/bin/activate
module load intel/18.0 intelmpi/18.0 R/3.6.3
module load gnuplot/5.2.2

# Working & temp directory
wd="/scratch/csm6hg/barnacle/"
outdir="/scratch/csm6hg/barnacle/smcpp_outdir"

# Create folders
if [[ -d "${outdir}" ]]
then
	echo "Working tmp folder exist"
	echo "lets move on"
	date
else
	echo "Folder doesnt exist. Let us fix that."
	mkdir ${outdir}
	date
fi

# Extract input
samp=$( cat ${wd}/samples | grep "^$SLURM_ARRAY_TASK_ID," | cut -d',' -f2 )

# Joint frequency spectrum SMC
smc++ vcf2smc my.vcf.gz data/pop12.smc.gz <contig> pop1:${samp1} pop2:${samp2}
smc++ vcf2smc my.vcf.gz data/pop21.smc.gz <contig> pop2:${samp2} pop1:${samp1}

# Estimate demographic history
smc++ estimate -o ${outdir}/${samp}/ --cores 5 5.69e-9 --em-iterations 30 --timepoints 1 1e8 ${outdir}/${samp}.*.smc.gz

# Plot
smc++ plot --cores 5 -g 0.2 -c ${outdir}/${samp}/${samp}.pdf ${outdir}/${samp}/*.json

# Finish
echo "Finish"
