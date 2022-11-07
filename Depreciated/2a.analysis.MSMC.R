# Read in msmc output and visualize
# Connor Murray 10.25.2021
# module load goolf/7.1.0_3.1.4 R/4.0.3; module load gdal geos proj; R

# Packages
library(data.table)
library(tidyverse)
library(foreach)
require(scales)
library(colortools)

# Working directory
setwd('/scratch/csm6hg/barnacle/')

# Mutation rate 
mu=2.8e-09

# Generations per year
gen=1

# MSMC output files
file <- c("merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.500kb.filtq35.fixr.msmc.final.txt",
          "merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.500kb.18segs.filtq35.fixr.msmc.final.txt",
          "merged_P6355_P8901_Bi02.bwa.sortbx.haploid.sort.500kb.2segs.filtq35.fixr.msmc.final.txt",
          "P9022_Bi03.bwa.sortbx.haploid.sort.500kb.filtq35.fixr.msmc.final.txt",
          "P9022_Bi03.bwa.sortbx.haploid.sort.500kb.18segs.filtq35.fixr.msmc.final.txt",
          "P9022_Bi03.bwa.sortbx.haploid.sort.500kb.2segs.filtq35.fixr.msmc.final.txt",
          "pool.500kb.filtq35.fixr.msmc.final.txt")


# Combine all MSMC output
out <- foreach(i=1:length(file), .combine = "rbind", .errorhandling = "remove") %do% {
  
  # Read file
  fin <- data.table(fread(file=file[i]),
                    name=tstrsplit(file[i], ".", fixed=T)[[1]],
                    seg=tstrsplit(file[i], ".", fixed=T)[[7]],
                    iteration=i)
  
  # Finish
  return(fin)

}

out <- out %>% mutate(segs=case_when(seg=="18segs" ~ "Default",
                              seg=="2segs" ~ "Previously published",
                              seg=="filtq35" ~ "Default filtering",
                              seg=="txt" ~ "Pooled Samples"))

write.csv(out, file="/scratch/csm6hg/barnacle_smcpp/outdir/msmc_barnacle.csv", quote = F, row.names = F)

# Output image
pdf("plots/barnacle_pool.pdf")

# Through time MSMC
ggplot(out, 
       aes(x = left_time_boundary/mu*gen, 
           y = (1/lambda)/(2*mu),
           color = name)) +
  geom_step(size=1.6) +
  facet_wrap(~segs) +
  scale_x_log10(labels=trans_format("log10", math_format(10^.x))) +
  scale_y_log10(labels=trans_format("log10", math_format(10^.x))) +
  theme_bw() +
  labs(x="Years ago (g=1, u=2.8e-9)", 
       y="Effective population size",
       color="",
       title="") +
  theme_bw() +
  theme(legend.text = element_text(face="bold", size=16),
        legend.title = element_text(face="bold", size=18),
        legend.background = element_blank(),
        legend.position = "bottom",
        title = element_text(face="bold", size=20),
        axis.text.x = element_text(face="bold", size=18),
        strip.text = element_text(face = "bold", size=18),
        axis.text.y = element_text(face="bold", size=18),
        axis.title.x = element_text(face="bold", size=22),
        axis.title.y = element_text(face="bold", size=22))

dev.off()