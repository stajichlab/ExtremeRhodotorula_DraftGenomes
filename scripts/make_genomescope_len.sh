#!/usr/bin/bash -l
pushd genomescope
grep Haploid */summary.txt  | perl -p -e 's#/summary.txt:Genome Haploid Length\s+(\S+)\s+bp\s+(\S+)\s+bp#\t$1#' | sort -k2,2nr > ../genomescope_sizes.tsv
