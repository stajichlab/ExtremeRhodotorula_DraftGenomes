#!/bin/bash -l
#SBATCH -p highmem --time 6-0:00:00 --ntasks 32 --nodes 1 --mem 256G --out logs/annotate_train.%a.log

module unload miniconda3
module load funannotate

MEM=256G
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes_to_annotate
ODIR=annotation
SAMPLES=samples.csv
RNAFOLDER=lib/RNASeq
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPLES | awk '{print $1}')
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPLES"
    exit
fi

export PASAHOME=$HOME/.pasa
echo $PASAHOME
IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read ID BASE SRA SPECIES STRAIN LOCUSTAG BIOPROJECT BIOSAMPLE NOTES
do
    if [[ "$NOTES" == "Too Low" ]]; then
	    echo "skipping $N ($ID) as it is too low coverage ($NOTES)"
	    continue
    fi
    echo "$ID $BASE $SRA $SPECIES $STRAIN"
    SPECIESSTRAINNOSPACE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/[\(\)\s]+/_/g')
    SPECIESNOSPACE=$(echo -n "$SPECIES" | perl -p -e 's/[\(\)\s]+/_/g')
    name=$SPECIESSTRAINNOSPACE
    
    # previous we were running flye and canu    
    MASKED=$INDIR/${SPECIESSTRAINNOSPACE}.AAFTF.masked.fasta
    echo "in is $MASKED ($INDIR/${name})"
    if [ ! -f $MASKED ]; then
	    echo "no masked file $MASKED"
	    exit
    fi
    if [[ -f $RNAFOLDER/${SPECIESNOSPACE}_R1.fastq.gz ]]; then
    	funannotate train -i $MASKED -o $ODIR/${name} \
   	     --jaccard_clip --species "$SPECIES" --isolate $STRAIN \
  	     --cpus $CPU --memory ${MEM} \
  	     --left $RNAFOLDER/${SPECIESNOSPACE}_R1.fastq.gz \
	     --right $RNAFOLDER/${SPECIESNOSPACE}_R2.fastq.gz \
  	     --pasa_db mysql
    elif [[ -f $RNAFOLDER/${SPECIESNOSPACE}.fastq.gz ]]; then
	    funannotate train -i $MASKED -o $ODIR/${name} \
   	     --jaccard_clip --species "$SPECIES" --isolate $STRAIN \
  	     --cpus $CPU --memory ${MEM} \
  	     --single $RNAFOLDER/${SPECIESNOSPACE}.fastq.gz \
  	     --pasa_db mysql
    else
	    echo "no RNAfiles for $SPECIESNOSPACE in $RNAFOLDER"
	    exit
    fi
done
