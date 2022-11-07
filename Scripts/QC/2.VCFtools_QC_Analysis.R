# Compile and output vcftools QC data 
# This script will concatenate all QC output files from chromosomes per VCF file
# module load goolf/7.1.0_3.1.4 R/4.0.3; module load gdal geos proj; R

# Libraries
library(data.table)
library(tidyverse)

# Working directory
setwd("/scratch/csm6hg/barnacle/split_pool/")

# Data
pi <- data.table(fread("pool.windowed.pi"))
het <- data.table(fread("pool.het"))

# Individual based missing and depth
fin %>% 
  ggplot(.,
         aes(x=value,
             y=Species)) + 
  geom_jitter(size =1.2, 
             shape = 21, 
             fill ="grey") + 
  facet_wrap(~name, scales = "free_x") +
  geom_vline(data=fin[name=="mean.miss"], 
             aes(xintercept = c(0.2)), linetype=2, size=1.3) +
  geom_vline(data=fin[name=="mean.dep"], 
             aes(xintercept = c(10)), linetype=2, size=1.3) +
  theme_bw() + 
  labs(x="Average missingness or depth",
       y="Species",
       title="Raw VCF Quality Control") +
  theme(axis.text.x = element_text(face = "bold", size = 14),
        axis.text.y = element_text(face = "bold.italic", size = 14),
        axis.title.x = element_text(face = "bold", size = 18),
        axis.title.y = element_text(face = "bold", size = 18),
        title = element_text(face = "bold", size=18), 
        strip.text =  element_text(face = "bold", size = 20))

dev.off()
