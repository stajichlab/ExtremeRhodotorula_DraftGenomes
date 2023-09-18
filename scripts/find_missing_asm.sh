#!/usr/bin/bash -l
for a in $(grep -v "Too Low" samples.csv | tail -n +2 | cut -f1 -d,)
do
    if [[ ! -f asm/AAFTF/$a.spades.fasta && ! -f asm/AAFTF/$a.spades.fasta.gz ]];
    then
	echo "$a"
    fi
done
