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
cutoff_taxcount = max * 0.90
cutoff_peplen = 400
cutoff_treeness = 0.4
treeinfoAA <- treeinfoAAall %>% filter(TAXCOUNT >= cutoff_taxcount & ALNLEN >= cutoff_peplen & treeness >= cutoff_treeness)
treeinfoCDS <- treeinfoCDSall %>% filter(TAXCOUNT >= cutoff_taxcount & ALNLEN >= cutoff_peplen*3 & treeness >= cutoff_treeness)
write_tsv(treeinfoAA,sprintf("%s/gene_trees/gene_trees.%s.filtered_tax90p_%s.tsv",outdir,HMM,'PEP'))
write_tsv(treeinfoCDS,sprintf("%s/gene_trees/gene_trees.%s.filtered_tax90p_%s.tsv",outdir,HMM,'CDS'))
