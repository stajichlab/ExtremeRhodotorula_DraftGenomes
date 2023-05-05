#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 2 --mem 4gb --out logs/stats.log

module load AAFTF

SAMPLEFILE=samples.csv
INDIR=asm
OUTDIR=genomes

mkdir -p $OUTDIR
IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read ID BASE SRA SPECIES STRAIN LOCUSTAG BIOPROJECT BIOSAMPLE
do
    # this used to be setup for different assembly methods too
    for type in AAFTF
    do
	if [ ! -f $INDIR/$type/$ID.sorted.fasta ]; then
		echo "cannot find $INDIR/$type/$ID.sorted.fasta"
		continue
	fi
	rsync -a $INDIR/$type/$ID.sorted.fasta $OUTDIR/$STRAIN.$type.fasta
	if [[ ! -f $OUTDIR/$STRAIN.$type.stats.txt || $OUTDIR/$STRAIN.$type.fasta -nt $OUTDIR/$STRAIN.$type.stats.txt ]]; then
    	    AAFTF assess -i $OUTDIR/$STRAIN.$type.fasta -r $OUTDIR/$STRAIN.$type.stats.txt
	fi
    done
done
