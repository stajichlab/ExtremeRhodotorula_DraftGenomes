#!/usr/bin/bash -l

for a in $(grep Low samples.csv | cut -d, -f5); do rm -f genomes/$a.AAFTF.fasta genomes/$a.AAFTF.stats.txt; done
