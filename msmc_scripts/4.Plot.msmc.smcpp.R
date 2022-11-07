# Compile SMC++ output
# Connor Murray 4.21.2022
# ijob -c 10 --mem=40G -p standard -A berglandlab_standard
# module load goolf/7.1.0_3.1.4 R/4.0.3; module load gdal geos proj; R

# Libraries
library(foreach)
library(data.table)
library(tidyverse)
require(scales)

# SMC++ Output
setwd('/scratch/csm6hg/')

# Mutation rate
mu=2.76e-08

# Generations per year
gen=1

# Output smcpp
smc <- data.table(read.csv("/scratch/csm6hg/barnacle_smcpp/outdir/barn1_split.csv") %>% 
      mutate(x1 = x,
             y1 = y) %>% 
      select(x1, y1),
      name="Pooled",
      analysis="SMC++",
      run="Pooled")

smcpp_sep <- data.table(read.csv("/scratch/csm6hg/barnacle_smcpp/outdir/barnacle.smcpp.split.csv") %>% 
      select(name=Species, x1=x, y1=y),
      analysis="SMC++",
      run="Independent")

# Output smcpp
msmc <- data.table(fread(file = "/scratch/csm6hg/barnacle/pool.500kb.filtq35.fixr.msmc.final.txt") %>% 
      mutate(x1 = left_time_boundary/mu*gen, 
             y1 = (1/lambda)/(2*mu)) %>% 
      select(x1, y1),
      name="Pooled",
      analysis="MSMC2",
      run="Pooled")

msmc_sep <- data.table(
  data.table(read.csv(file = "/scratch/csm6hg/barnacle_smcpp/outdir/msmc_barnacle.csv"))[seg=="2segs"] %>% 
      mutate(x1 = left_time_boundary/mu*gen, 
             y1 = (1/lambda)/(2*mu)) %>% 
      select(x1, y1, name),
      analysis="MSMC2",
      run="Independent")

tot_m <- data.table(rbind(msmc_sep, msmc))
tot_s <- data.table(rbind(smcpp_sep, smc)) %>% mutate(name=case_when(name== "merged"~ "merged_P6355_P8901_Bi02",
                                                                        name=="P9022" ~ "P9022_Bi03",
                                                                        TRUE ~ as.character(name)))

require(scales)

#pdf("/scratch/csm6hg/barnacle_smcpp/msmc.smcpp.barnacle.new.pdf", width=14, height=10)

# Through time MSMC
ggplot() +
  geom_smooth(data=tot_s,
         aes(x = x1,
             y = y1,
             color=name, 
             linetype = analysis), 
         size = 2.2, se=F) +
  geom_step(data=tot_m, 
            aes(x = x1, 
                y = y1,
                color=name,
                linetype = analysis), 
              size = 2.2) +
  facet_grid(~run) +
  annotation_logticks(scaled = TRUE) +
  scale_x_log10(labels = trans_format("log10", math_format(1^.x)),
                limits = c(1000, 1000000)) +
  scale_y_log10(labels = trans_format("log10", math_format(1^.x)),
                limits = c(2e3, 2e6)) +
  theme_classic() +
  scale_color_manual(values=c("merged_P6355_P8901_Bi02"="#E69F00", "P9022_Bi03"="#0072B2", "Pooled"="#000000")) +
  labs(x=paste("Years ago (g=", gen, ", u=", mu, ")", sep=""), 
       y="Effective population size",
       color="",
       linetype="") +
  theme(legend.text = element_text(face="bold", size=22),
        legend.title = element_text(face="bold", size=22),
        legend.background = element_blank(),
        strip.text = element_blank(),
        legend.position= "bottom",
        axis.text.x = element_text(face="bold", size=22),
        axis.text.y = element_text(face="bold", size=22),
        axis.title.x = element_text(face="bold", size=24),
        axis.title.y = element_text(face="bold", size=24))

dev.off()