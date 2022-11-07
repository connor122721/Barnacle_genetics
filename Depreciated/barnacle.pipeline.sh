# Script for estimating barnacle demographic history
# Connor Murray
# 10.1.2021

# Parameters
wd="/scratch/csm6hg/barnacle"
bam=${wd}/P9022_Bi03.bwa.sortbx.haploid.bam
ref=${wd}/haploid_assembly_BUSCOmancur.fasta


# Load modules
module load samtools

# Index reference genome fasta
samtools faidx ${ref}

# Extract chromosome names
cut ${ref}.fai -f1,2 > chromsizes

# Extract large chromosomes (>10 MBs)


# Index bam file
samtools sort ${bam} -o P9022_Bi03.bwa.sortbx.haploid.sort.bam

# Collect quality metrics
module load fastqc
fastqc ${wd}/P9022_Bi03.bwa.sortbx.haploid.sort.bam

# Load modules
module load samtools/1.10
module load bcftools/1.9
module load htslib/1.9
module load psmc/0.6.5
module load gnuplot/5.2.2

# Convert BAM to VCF
bcftools mpileup ${bam} --no-reference | bcftools call -cv -Oz -o ${wd}/barnacle.vcf.gz
bcftools index ${wd}/barnacle.vcf.gz -t

# Create consensus sequence and input for PSMC
bcftools consensus ${wd}/barnacle.vcf.gz | vcfutils.pl vcf2fq > barnacle.fq

# Convert FQ to PSMCFA
/project/berglandlab/connor/psmc/utils/fq2psmcfa -q 20 barnacle.fq.gz > ${wd}/barnacle.psmcfa

# Run PSMC
psmc -N25 -t15 -r1.75 -p "4+25*2+4+6" -o ${wd}/barnacle.psmc ${wd}/barnacle.psmcfa
