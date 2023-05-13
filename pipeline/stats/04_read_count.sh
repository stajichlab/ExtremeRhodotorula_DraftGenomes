#!/usr/bin/bash -l

#SBATCH --nodes 1 --ntasks 24 --mem 24G -p batch -J readcount --out logs/bbcount.%a.log --time 48:00:00
module load BBMap
hostname
MEM=24
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

INDIR=input
SAMPLEFILE=samples.csv

ASM=genomes
OUTDIR=$(realpath mapping_report)
mkdir -p $OUTDIR

IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read ID BASE SRA SPECIES STRAIN LOCUSTAG BIOPROJECT BIOSAMPLE NOTES
do
    if [[ "$NOTES" == "Too Low" ]]; then
	echo "skipping $N ($ID) as it is too low coverage ($NOTES)"
	
   fi
    
    LEFTIN=$INDIR/${BASE}_1.fastq.gz
    RIGHTIN=$INDIR/${BASE}_2.fastq.gz
    if [ ! -f $LEFTIN ]; then
	    BASE=$(echo -n $BASE | perl -p -e 's/_R\S+//')
	    LEFTIN=$INDIR/${BASE}_R1_001.fastq.gz
	    RIGHTIN=$INDIR/${BASE}_R2_001.fastq.gz
	    if [ ! -f $LEFTIN ]; then
     		echo "no $LEFTIN file for $ID/$BASE in $FASTQ dir"
     		exit
	    fi
    fi
    LEFT=$(realpath $LEFTIN)
    RIGHT=$(realpath $RIGHTIN)
    echo "$LEFT $RIGHT"
    for type in AAFTF
    do
	SORTED=$(realpath $ASM/${ID}.AAFTF.fasta)
	REPORTOUT=${ID}.${type}
	if [ -s $SORTED ]; then
	    pushd $SCRATCH
	    if [ ! -s $OUTDIR/${REPORTOUT}.bbmap_covstats.txt ]; then
		bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT in2=$RIGHT covstats=$OUTDIR/${REPORTOUT}.bbmap_covstats.txt  statsfile=$OUTDIR/${REPORTOUT}.bbmap_summary.txt
	    fi
	    popd
	fi
    done
done

