# Read in msmc output and visualize
# Connor Murray 10.25.2021
# module load goolf/7.1.0_3.1.4 R/4.0.3; module load gdal geos proj; R

# Packages
library(data.table)
library(tidyverse)
library(foreach)
library(colortools)

# Working directory
setwd('/scratch/csm6hg/barnacle/')

# Mutation rate 
mu=2.8e-09

# Generations per year
gen=1

# MSMC output files
file <- c("combined.merged.500kb.msmc.final.txt",
          "combined.P9022.500kb.msmc.final.txt")

# Combine all MSMC output
out <- foreach(i=1:length(file), .combine = "rbind") %do% {

  # Read file
  fin <- data.table(fread(file=file[i]),
                    name=tstrsplit(file[i], ".", fixed=T)[[2]],
                    #seg=tstrsplit(file[i], ".", fixed=T)[[7]],
                    iteration=i)
  
  # Finish
  return(fin)

}

# Output image
pdf("independent.runs.500kb.pdf")

10^3
10^4
# Through time MSMC
ggplot(out, 
       aes(x = left_time_boundary/mu*gen, 
           y = (1/lambda)/(2*mu),
           color = name)) +
  geom_step(size=1.6) +
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

# MSMC output files
file2 <- list.files(pattern = "combined.msmc.final.txt")

# Read file
fin2 <- data.table(fread(file=file2))

# Wide to long
fin.dt <- data.table(fin2 %>% 
                     group_by(time_index) %>% 
                     pivot_longer(cols=c(lambda_00, lambda_01, lambda_11)) %>%
                     mutate(name=case_when(name == "lambda_00" ~ "merged_P6355_P890",
                                           name == "lambda_01" ~ "Cross",
                                           name == "lambda_11" ~ "P9022_Bi03")))

# Through time MSMC
ggplot(fin.dt[!name=="Cross"], 
       aes(color = name,
           x = left_time_boundary/mu*gen, 
           y = (1/value)/(2*mu))) +
  geom_step(size=1.6) +
  scale_x_log10(labels=trans_format("log10", math_format(10^.x))) +
  scale_y_log10(labels=trans_format("log10", math_format(10^.x))) +
  theme_bw() +
  labs(x="Years ago (g=1, u=2.8e-9)", 
       y="Effective population size",
       color="") +
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

# Cross coalesent rate
out.dt <- data.table(fin2 %>% 
                     mutate(ccr = 2*lambda_01/(lambda_00+lambda_11)))

pdf("rccr.msmc.pdf")

# Cross coalesent rate 
ggplot(out.dt[ccr <= 1], 
       aes(x = left_time_boundary/mu*gen, 
           y = ccr)) +
  geom_step(size=1.6) +
  scale_x_log10(labels=trans_format("log10", math_format(10^.x))) +
  ylim(c(0,1)) +
  theme_bw() +
  labs(x="Years ago (g=1, u=2.8e-9)", 
       y="Relative cross coalesent rate",
       color="") +
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
