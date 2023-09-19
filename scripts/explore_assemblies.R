#!/usr/bin/env R
library(ggplot2)
library(tidyerse)
library(purrr)
library(readr)

asminfo <- read_tsv("asm_stats.tsv",col_names=TRUE)
