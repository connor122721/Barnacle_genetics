# Compile SMC++ output
# Connor Murray 1.4.2021
# module load goolf/7.1.0_3.1.4 R/4.0.3; module load gdal geos proj; R

# Libraries
library(foreach)
library(data.table)
library(tidyverse)
library(rjson)

# SMC++ Output
setwd('/scratch/csm6hg/barnacle_smcpp/outdir')

# Extract all model files
tbl <- list.files(pattern = "pool.split.final.json", recursive=TRUE)

# Read in files as table
out.dt <- foreach(i=1:length(tbl), .combine="rbind") %do% {
  
  # Read in files as table
  out <- data.table(read.table(tbl[i], header=T, sep = ","), 
                    Species=tstrsplit(tbl[[i]], "_")[[1]],
                    Sample=gsub(tstrsplit(tbl[[i]], "_")[[2]], 
                                pattern = ".csv", 
                                replacement = ""),
                    csv=tbl[[i]],
                    iteration=i)
  
  print(i)
  
  # Finish  
  return(out)
  
}

# Output smcpp
# write.csv(x = out.dt, file = "barnacle.smcpp.split.csv", row.names = F, quote = F)
out.dt <- data.table(read.csv("barnacle.smcpp.split.csv"))

require(scales)

# Mutation rate
mu=2.76e-08

# Generations per year
gen=1

#pdf("barnacle.smcpp.pdf", width=12, height=6)

# Through time MSMC
out.dt  %>%
  ggplot(., 
         aes(x = x,
             y = y,
             color = csv)) +
  geom_smooth(size = 2.2, 
              se=FALSE) +
  annotation_logticks(scaled = TRUE) +
  scale_x_log10(labels = trans_format("log10", math_format(10^.x)),
                limits = c(10^3, 10^6)) +
  scale_y_log10(labels = trans_format("log10", math_format(10^.x)),
                limits = c(10^4, 10^6)) +
  theme_bw() +
  labs(x=paste("Years ago (g=", gen, ", u=", mu, ")", sep=""), 
       y="Effective population size",
       color="") +
  theme_bw() +
  theme(legend.text = element_text(face="bold", size=18),
        legend.title = element_text(face="bold", size=18),
        legend.background = element_blank(),
        strip.text = element_text(face="bold.italic", size = 18),
        legend.position= "bottom",
        axis.text.x = element_text(face="bold", size=18),
        axis.text.y = element_text(face="bold", size=18),
        axis.title.x = element_text(face="bold", size=22),
        axis.title.y = element_text(face="bold", size=22))

dev.off()