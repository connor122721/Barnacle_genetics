#!/usr/bin/env bash
#SBATCH -J smcpp-barnacle # A single job name for the array
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 1-00:00 # Running time of 1 hour
#SBATCH --mem 30G # Memory request of 100GB
#SBATCH -o  /scratch/csm6hg/barnacle_smcpp/smcpp_run.out # Standard output
#SBATCH -e  /scratch/csm6hg/barnacle_smcpp/smcpp_run.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard

# Load SMC++ & Modules
source /home/csm6hg/smcpp/bin/activate
module load gnuplot/5.2.2

# Working & temp directory
wd="/scratch/csm6hg/barnacle"

# Reference genome
ref=${wd}/haploid_assembly_BUSCOmancur.fasta

# Output
outdir="/scratch/csm6hg/barnacle_smcpp/outdir"

# Chromosome file
intervals=${wd}/chrom.500kb.sizes

# Metadata
meta="/scratch/csm6hg/barnacle_smcpp/barncle.list"

# Cores
threads=1

# Extract input
pop1="merged_P6355"
pop2="P9022"
samp1="merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort"
samp2="P9022_Bi03.bwa.sortbx.haploid.sort"
bam1="/scratch/csm6hg/barnacle/merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.bam"
bam2="/scratch/csm6hg/barnacle/P9022_Bi03.bwa.sortbx.haploid.sort.bam"

# Make conditional directories
[ ! -d ${outdir}/ ] && mkdir ${outdir}/
[ ! -d ${outdir}/${pop1}}/ ] && mkdir ${outdir}/${pop1}/
[ ! -d ${outdir}/${pop2}/ ] && mkdir ${outdir}/${pop2}/
[ ! -d ${outdir}/pool/ ] && mkdir ${outdir}/pool/

# Create combined chromosome samples
while read -r i stop; do
  #i=Bi03_p1mp_000216F; stop=960886

  # Progress message
  echo ${i} "Length:" ${stop}

  # Index VCFs
  if [ -f ${wd}/split_${samp1}/${samp1}.${i}.filtq35.vcf.gz.tbi ]; then
     echo ${samp1} "tabix file here"
   else
    gunzip ${wd}/split_${samp1}/${samp1}.${i}.filtq35.vcf.gz
    bgzip ${wd}/split_${samp1}/${samp1}.${i}.filtq35.vcf
    tabix ${wd}/split_${samp1}/${samp1}.${i}.filtq35.vcf.gz
  fi

  if [ -f ${wd}/split_${samp2}/${samp2}.${i}.filtq35.vcf.gz.tbi ]; then
      echo ${samp2} "tabix file here"
    else
     gunzip ${wd}/split_${samp2}/${samp2}.${i}.filtq35.vcf.gz
     bgzip ${wd}/split_${samp2}/${samp2}.${i}.filtq35.vcf
     tabix ${wd}/split_${samp2}/${samp2}.${i}.filtq35.vcf.gz
  fi

  # Pop1 1D sfs - create input file
  smc++ vcf2smc \
  ${wd}/split_${samp1}/${samp1}*${i}.filtq35.vcf.gz \
  --cores ${threads} \
  --length ${stop} \
  -c 10000 \
  ${outdir}/${pop1}/${pop1}.${samp1}.${i}.filtq35.smc.gz \
  ${i} \
  ${bam1}:${bam1}

  # Pop2 1D sfs - create input file
  smc++ vcf2smc \
  ${wd}/split_${samp2}/${samp2}*${i}.filtq35.vcf.gz \
  --cores ${threads} \
  --length ${stop} \
  -c 10000 \
  ${outdir}/${pop2}/${pop2}.${samp2}.${i}.filtq35.smc.gz \
  ${i} \
  ${bam2}:${bam2}

  # Pool samples
  smc++ vcf2smc \
  ${wd}/split_pool/pool.${i}.filtq35.vcf.gz \
  --cores ${threads} \
  --length ${stop} \
  -c 10000 \
  ${outdir}/pool/pool.barn1.${i}.filtq35.smc.gz \
  ${i} \
  barn1:/scratch/csm6hg/barnacle/merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.bam,/scratch/csm6hg/barnacle/P9022_Bi03.bwa.sortbx.haploid.sort.bam

done < ${intervals}

# Estimate demographic history - pop1
smc++ estimate \
-o ${outdir} \
--base ${pop1}_${samp1}_split \
--cores ${threads} \
--em-iterations 30 \
--timepoints 1000 5e6 \
2.76e-08 \
${outdir}/${pop1}/${pop1}.${samp1}.*.smc.gz

# Estimate demographic history - pop2
smc++ estimate \
-o ${outdir} \
--base ${pop2}_${samp2}_split \
--em-iterations 30 \
--timepoints 1000 5e6 \
--cores ${threads} \
2.76e-08 \
${outdir}/${pop2}/${pop2}.${samp2}.*.smc.gz

# Estimate demographic history - pooled
smc++ estimate \
-o ${outdir} \
--base barn1_split \
--em-iterations 30 \
--timepoints 1000 5e6 \
--cores ${threads} \
2.76e-08 \
${outdir}/pool/pool.barn1.*.smc.gz

smc++ plot \
barn1_split.pdf \
pool.split.final.json \
-g 1 \
-c

# Finish
echo "Finish"
