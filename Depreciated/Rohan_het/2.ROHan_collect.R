# Heterozygosity analyses of ROHan output
# Connor Murray
# 4.11.2022

# module load intel/18.0 intelmpi/18.0 R/3.6.3; R

# Libraries
library(data.table)
library(tidyverse)
library(foreach)

# Working directory
setwd("/project/berglandlab/connor/rohan/hybrids/")

# Lists all files with pattern 
filenames <- list.files(pattern = ".summary")

# Read in summary file loop
out <- foreach(i = 1:length(filenames), .combine="rbind") %do% {

  # Read in summary files
  theta <- read.delim(filenames[i], header = FALSE, sep = c("\t"))[3:4,2:4]
  dt1 <- data.table(theta)
  setnames(setDT(dt1), c("global", "min", "max"))
  dt1 <- data.table(dt1 %>% mutate(global=as.numeric(as.character(global)), 
                                   min=as.numeric(min), 
                                   max=as.numeric(max)))
  
  # Finish theta
  dt1 <- cbind(data.table(dt1, sample = sub('.summary.txt*', '', filenames[i])))

  # Remainder of output files
  output <- unlist(read.delim(filenames[i], header = FALSE, sep = c("\t"))[5:11,2])
  dt2 <- data.table(output)
  dt2 <- dt2[, c("global", "min", "max") := tstrsplit(gsub("[()]", "", output), "[ ,]")]
  dt2 <- data.table(dt2 %>% mutate(global=as.numeric(as.character(global)), 
                                   min=as.numeric(min), 
                                   max=as.numeric(max)))
  
  # Finish output
  dt2 <- cbind(data.table(dt2[,2:4], sample = sub('.summary.txt*', '', filenames[i])))
  
  # Rbind final and rename rows
  fin <- rbind(dt1, dt2)
  fin <- fin[, data:=c("theta_out_ROH", "theta_inc_ROH", "seg_un", "seg_un_%",
                       "seg_in_ROH", "seg_in_ROH%", "seg_out_ROH", "seg_out_ROH%",
                        "avg_len_ROH")]
  
  #fin$clone <- sub(fin$sample, pattern = "_finalmap_mdup.bam", replacement = "")
  
  return(fin)
}

# Write output
write.csv(out, file = "barnacle.rohan.csv", quote = F, row.names = F)

# Data
out <- data.table(read.csv("C:/Users/Conno/Desktop/gitmaster/daphnia_demography/ROHan_analyses/hybrids.daphnia.rohan.csv"))

# Aggregate summary results
theta.ag <- data.table(out %>% group_by(data, SC) %>% 
                         select(c(global, min, max, data, SC)) %>%  
                         summarise_all(list(mean = ~ mean(.),
                                            median = ~ median(.))))

# global theta across ponds - 
ggplot(out[data%in%c("theta_out_ROH", "theta_inc_ROH")], 
       aes(x=SC, y=global, color=data)) +
  geom_boxplot(position = position_dodge(1)) +
  scale_color_discrete(labels = c("Including ROH", "Outside ROH")) +
  labs(x="Year", y="Watterson's theta") +
  theme_bw() + 
  theme(legend.title = element_blank())  

# lists all files with pattern 
filenames <- list.files(pattern = ".hEst")

# empty vector
het <- list()

# read in output files loop
for(i in 1:length(filenames)) {
  
  # adds sample name
  het[[i]] <- data.table(fread(filenames[i]), 
                       sample = sub('.hEst*', '', filenames[i]),
                       year = tstrsplit(filenames[i], "_")[[2]],
                       pond = tstrsplit(filenames[i], "_")[[3]])
}

# rbind all files
het <- rbindlist(het)
colnames(het)[1] <- "CHROM"

# Merge with metadata for clone assignment
het <- left_join(het, out %>% select(sample, bam, clone, SC) %>% unique(), by="sample")

# Aggregate het results
hest.ag <- data.table(het %>% na.omit() %>% group_by(clone, pond, year, SC) %>% 
                        select(c(h, err, hLow, hHigh, clone, pond, year, SC)) %>%  
                        summarise_all(list(mean = ~ mean(.),
                                           median = ~ median(.))))

# OO clones heterozygosity
ggplot(hest.ag[pond %in% c("D8", "DBunk")][SC=="OO"], aes(x=year, y=h_mean)) +
  geom_boxplot() +
  facet_wrap(~pond) +
  labs(x="Year", y="Local heterozygosity rate", 
       title= "Sexual output - Average 10 kb heterozygosity") +
  theme_bw() +
  theme(legend.position="none")

# non-OO clones heterozygosity
ggplot(hest.ag[pond %in% c("D8", "DBunk")][!SC=="OO"], aes(x=year, y=h_mean)) +
  geom_boxplot() +
  facet_wrap(~pond) +
  labs(x="Year", y="Local heterozygosity rate", 
       title= "Clonal output - Average 10 kb heterozygosity") +
  theme_bw() +
  theme(legend.position="none")

# Merging het and output results
hest.ag.mer <- data.table(merge(out, hest.ag, 
                                by=c("pond", "SC", "year", "clone")))

# theta and ROH length - diagnostic
ggplot(hest.ag.mer[!global==0][data%in%c("theta_inc_ROH", "theta_out_ROH")], 
       aes(x=global, y=h_median)) +
  geom_point(alpha=0.4)  +
  geom_smooth(method = "glm", se = FALSE, linetype=2) +
  labs(x="Theta pi", y="Median local heterozygosity", 
       title= "All clones") +
  facet_wrap(~data) +
  theme_bw() + 
  theme(legend.title = element_blank())  

