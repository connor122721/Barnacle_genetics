# Representative individual per country and species
# Connor Murray 10.18.2021
# module load goolf/7.1.0_3.1.4 R/4.0.3; module load gdal geos proj; R

# Packages
library(data.table)
library(tidyverse)

# Working directory
setwd('/scratch/csm6hg/barnacle/')

# Metadata
fin <- data.table(fread("chromsizes"))
colnames(fin) <- c("Chrom", "Sizes")

# Restirct to 1mb
fin <- fin[Sizes >= 500000]

# Fix slurmid column
fin <- data.table(fin %>% mutate(slurmID=c(1:c(dim(fin)[1]))))

# Reorder
setcolorder(fin, c("slurmID", "Chrom", "Sizes"))

# Output parameter file
write.csv(fin,
          quote=F,
          row.names=F,
          file="chrom.txt")

# Output parameter file
write_delim(fin %>% select(-slurmID),
            delim="\t",col_names = F,
            file="chrom.500kb.sizes")
