library(tidyverse)
library(purrr)
library(readr)
library(fs)
library(dplyr)
library(stringr)
library(binr)
library(ggfortify)
library(ggplot2)
library(RColorBrewer)
library(scales)
library(viridis)

args = commandArgs(trailingOnly=TRUE)
outdir="Phylogeny"
HMM="fungi_odb10"
if (length(args) >=1 ) {
  outdir=args[2]
  if (length(args) >=2 ) {
    HMM = args[3] 
  }
}
pepin=sprintf("%s/gene_trees/gene_trees.%s.summarize_%s.tsv",outdir,HMM,'PEP')
cdsin=sprintf("%s/gene_trees/gene_trees.%s.summarize_%s.tsv",outdir,HMM,'CDS')
treeinfoAAall <- read_tsv(pepin)
treeinfoCDSall <- read_tsv(cdsin)

max=max(treeinfoAAall$TAXCOUNT)
cutoff_taxcount = max * 0.75
treeinfoAA <- treeinfoAAall %>% filter(TAXCOUNT >= cutoff_taxcount)
treeinfoCDS <- treeinfoCDSall %>% filter(TAXCOUNT >= cutoff_taxcount)
min(treeinfoAA$TAXCOUNT)
write_tsv(treeinfoAA,sprintf("%s/gene_trees/gene_trees.%s.filtered_tax75p_%s.tsv",outdir,HMM,'PEP'))
write_tsv(treeinfoCDS,sprintf("%s/gene_trees/gene_trees.%s.filtered_tax75p_%s.tsv",outdir,HMM,'CDS'))

hist(treeinfoAA$evoRate,100)
hist(treeinfoCDS$evoRate,100)

alnL <-quantile(quantile(treeinfoCDS$ALNLEN))
evoR <-quantile(quantile(treeinfoCDS$evoRate))

#plot(treeinfoAA$ALNLEN,treeinfoAA$mean_BSS)
#plot(treeinfoAA$ALNLEN,treeinfoAA$evoRate)

#plot(treeinfoCDS$ALNLEN,treeinfoCDS$mean_BSS)
#plot(treeinfoCDS$ALNLEN,treeinfoCDS$evoRate)

#pca_res <- prcomp(treeinfoAA[4:8], scale. = TRUE)
#autoplot(pca_res)
#autoplot(pca_res, data = treeinfoAA, colour = '')

#filteredCDS <- treeinfoCDS %>% filter(ALNLEN >= alnL[4])
#evoR <-quantile(quantile(filteredCDS$evoRate))

#filteredCDS2 <-filteredCDS %>% filter(evoRate <= evoR[1] | evoRate >= evoR[4])
#write_tsv(filteredCDS2,file.path(outdir,"filtered_quartileLenEvoRate_CDS.tsv"))


# generate the bins
#alnL <-bins(treeinfoCDS$ALNLEN,10)
#filteredCDS <- treeinfoCDS %>% filter(ALNLEN >= alnL[4])
treeinfoCDS$evocat <- cut(treeinfoCDS$evoRate,breaks=5,
               labels=1:5)
table(treeinfoCDS$evocat)

treeinfoCDS$lencat <- cut(log(treeinfoCDS$ALNLEN),breaks=5,
                          labels=1:5)
table(treeinfoCDS$lencat)
treeinfoCDS

plot(log(treeinfoCDS$ALNLEN),treeinfoCDS$evoRate)

#filteredCDS2 <-treeinfoCDS %>% filter(evoRate <= evoR[1] | evoRate >= evoR[4])
#write_tsv(filteredCDS2,file.path(outdir,"filtered_quartileLenEvoRate_CDS.tsv"))

#alnL <-quantile(quantile(treeinfoAA$ALNLEN))
#filteredAA <- treeinfoAA %>% filter(ALNLEN >= alnL[4])
#evoR <-quantile(quantile(filteredAA$evoRate))
#filteredAA2 <-filteredAA %>% filter(evoRate <= evoR[1] | evoRate >= evoR[4])
#write_tsv(filteredAA2,file.path(outdir,"filtered_quartileLenEvoRate_AA.tsv"))
