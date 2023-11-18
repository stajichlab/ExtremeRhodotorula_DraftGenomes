#!/usr/bin/bash -l
#SBATCH --nodes 1 --ntasks 8 --mem 16G --out logs/annotate_antismash.%a.log -J antismash

module load antismash
which antismash
hostname
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=annotation
SAMPLES=samples.csv
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
  N=$1
  if [ ! $N ]; then
    echo "need to provide a number by --array or cmdline"
    exit
  fi
fi
MAX=`wc -l $SAMPLES | awk '{print $1}'`

if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in $SAMPLES"
  exit
fi

INPUTFOLDER=predict_results
IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read ID BASE SRA SPECIES STRAIN LOCUSTAG BIOPROJECT BIOSAMPLE NOTES
do
    if [[ "$NOTES" == "Too Low" ]]; then
            echo "skipping $N ($ID) as it is too low coverage ($NOTES)"
            continue
    fi

    SPECIESSTRAINNOSPACE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/[\(\)\s]+/_/g')
    SPECIESNOSPACE=$(echo -n "$SPECIES" | perl -p -e 's/[\(\)\s]+/_/g')
    name=$SPECIESSTRAINNOSPACE
    echo "Species is $SPECIESNOSPACE"

    # previous we were running flye and canu
    GENOME=$INDIR/${SPECIESSTRAINNOSPACE}.AAFTF.masked.fasta
    if [ ! -d $OUTDIR/$name ]; then
	    echo "No annotation dir for ${name}"
	    exit
     fi
     echo "processing $OUTDIR/$name"
     if [[ ! -d $OUTDIR/$name/antismash_local || ! -s $OUTDIR/$name/antismash_local/index.html ]]; then
	     rm -rf $OUTDIR/$name/antismash_local
	    time antismash --taxon fungi --output-dir $OUTDIR/$name/antismash_local \
		 --genefinding-tool none --fullhmmer --clusterhmmer --cb-general \
		 --pfam2go -c $CPU $OUTDIR/$name/$INPUTFOLDER/*.gbk
     else
	     echo "antiSMASH already run for $name, skipping"
     fi
done
