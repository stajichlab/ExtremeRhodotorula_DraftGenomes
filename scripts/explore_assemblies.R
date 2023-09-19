#!/usr/bin/env R
library(ggplot2)
library(tidyverse)
library(purrr)
library(readr)
library(cowplot) # it allows you to save figures in .png file
library(RColorBrewer)
#library(smplot2)

asminfo <- read_tsv("asm_stats.tsv",col_names=TRUE) %>% mutate(ID=str_replace(SampleID, ".AAFTF", ""))
samples <- read_csv("samples.csv",col_names=TRUE) 
merged <- asminfo %>% left_join(samples,by = join_by(ID == Strain))
colourCount = length(unique(merged$Species))
getPalette = colorRampPalette(brewer.pal(8, "Dark2"))(colourCount)


p <- ggplot(data = merged, mapping = aes(x = Species, y = TOTAL_LENGTH/10**6,color=Species)) +
  geom_boxplot() + 
  geom_jitter(width = 0.15) +  theme_cowplot(12) + theme(legend.position="none") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) + 
  scale_color_manual(values=getPalette) +
  ylab("Length (Mb)") 

ggsave("genome_size_boxplot.pdf",p,width=18,height=14)

p2 <- ggplot(data = merged %>% filter(BUSCO_Complete > 75), 
             mapping = aes(x = log(Average_Coverage)/log(10), y=BUSCO_Complete,color=Species)) +
  geom_point()  +  theme_cowplot(12) + 
  scale_color_manual(values=getPalette) + xlab("Coverage (log(10))") + ylab("BUSCO Completeness") 
ggsave("genome_coverage.pdf",p2,width=18,height=14)

p3 <- ggplot(data = merged %>% filter(BUSCO_Complete > 75), 
             mapping = aes(x = TOTAL_LENGTH/10**6, y=BUSCO_Duplicate,color=Species)) +
  geom_point()  +  theme_cowplot(12)  + 
  scale_color_manual(values=getPalette) + xlab("Genome size (Mb)") + ylab("BUSCO Duplication")
ggsave("genome_dup_by_size.pdf",p3,width=18,height=14)


