#!/usr/bin/bash -l

#SBATCH --nodes 1 --ntasks 24 --mem 24G -p batch -J readcount --out logs/bbcount.%a.log --time 48:00:00
module load BBMap
module load workspace/scratch

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
FASTQDIR=$INDIR
SAMPLEFILE=samples.csv
TEMP=$SCRATCH
ASM=genomes
OUTDIR=$(realpath mapping_report)
mkdir -p $OUTDIR

IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read ID BASE SRA SPECIES STRAIN LOCUSTAG BIOPROJECT BIOSAMPLE NOTES
do
    if [[ "$NOTES" == "Too Low" ]]; then
	echo "skipping $N ($ID/$STRAIN) as it is too low coverage ($NOTES)"
    fi
    DONETHIS=0
    for type in AAFTF
    do
	REPORTOUT=${STRAIN}.${type}
	SORTED=$(realpath $ASM/${STRAIN}.${type}.fasta)
	if [[ -s $OUTDIR/${REPORTOUT}.bbmap_summary.txt && $OUTDIR/${REPORTOUT}.bbmap_summary.txt -nt $SORTED ]]; then
	    DONETHIS=1
	else
	    DONETHIS=0
	    break
	fi
    done
    
    if [[ $DONETHIS == "1" ]]; then
	exit
    fi
	
    LEFTIN=$INDIR/${BASE}_1.fastq.gz	    
    RIGHTIN=$INDIR/${BASE}_2.fastq.gz
    if [ ! -f $LEFTIN ]; then
	LEFTIN=$SCRATCH/${STRAIN}_R1.fastq.gz
	RIGHTIN=$SCRATCH/${STRAIN}_R2.fastq.gz
	for BASEPATTERN in $(echo $BASE | perl -p -e 's/\;/,/g');
	do
	    L=$INDIR/${BASEPATTERN}_1.fastq.gz
	    R=$INDIR/${BASEPATTERN}_2.fastq.gz
	    if [ ! -f $L ]; then
		B=$(echo -n $BASEPATTERN | perl -p -e 's/_R\S+//')
		L=$INDIR/${B}_R1_001.fastq.gz
		R=$INDIR/${B}_R2_001.fastq.gz
		if [ ! -f $L ]; then
		    echo "no $LEFTIN file for $ID/$B in $INDIR dir"
		    exit
		fi
	    fi
	    echo "concatenating $L to $LEFTIN"
	    echo "concatenating $R to $RIGHTIN"
	    cat $L >> $LEFTIN
	    cat $R >> $RIGHTIN
	done
    fi
    LEFT=$(realpath $LEFTIN)
    RIGHT=$(realpath $RIGHTIN)
    echo "$LEFT $RIGHT"
    for type in AAFTF
    do
	SORTED=$(realpath $ASM/${STRAIN}.${type}.fasta)
	REPORTOUT=${STRAIN}.${type}
	if [ -s $SORTED ]; then
	    pushd $SCRATCH
	    if [ ! -s $OUTDIR/${REPORTOUT}.bbmap_covstats.txt ]; then
		bbmap.sh -Xmx${MEM}g ref=$SORTED in=$LEFT in2=$RIGHT covstats=$OUTDIR/${REPORTOUT}.bbmap_covstats.txt  statsfile=$OUTDIR/${REPORTOUT}.bbmap_summary.txt
	    fi
	    popd
	else
	    echo "no $SORTED for $STRAIN ($ID) file"
	fi
    done
done

