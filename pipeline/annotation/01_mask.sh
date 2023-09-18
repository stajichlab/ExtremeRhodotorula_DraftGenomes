#!/bin/bash -l
#SBATCH -p short -c 8 -n 1 --nodes 1 --mem 48G --out logs/annotate_mask.%a.log

module unload miniconda3

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=genomes_to_annotate
MASKDIR=RepeatMasker_run
SAMPLES=samples.csv
RMLIBFOLDER=lib/repeat_library
mkdir -p $RMLIBFOLDER $MASKDIR $OUTDIR
RMLIBFOLDER=$(realpath $RMLIBFOLDER)

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

IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read ID BASE SRA SPECIES STRAIN LOCUSTAG BIOPROJECT BIOSAMPLE NOTES
do
    if [[ "$NOTES" == "Too Low" ]]; then
	echo "skipping $N ($ID $STRAIN) as it is too low coverage ($NOTES)"
	continue
    fi
    SPECIESNOSPACE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/[\(\)\s]+/_/g')

    for type in AAFTF 
    do
	name=$STRAIN.$type
	if [ ! -f $INDIR/${name}.fasta ]; then
		echo "Cannot find $name.fasta in $INDIR - may not have been run yet"
		exit
	fi
	OUTNAME=$OUTDIR/${SPECIESNOSPACE}.${type}.masked.fasta
	if [[ ! -s $OUTNAME || $INDIR/${name}.fasta -nt $OUTNAME ]]; then
	    mkdir -p $MASKDIR/${name}
	    GENOME=$(realpath $INDIR/${name}.fasta)
	    if [ ! -f $MASKDIR/${name}/${name}.fasta.masked ]; then
		LIBRARY=$RMLIBFOLDER/$SPECIESNOSPACE.repeatmodeler.lib
		if [ ! -f $LIBRARY ]; then
			module load RepeatModeler
			pushd $MASKDIR/${name}
			BuildDatabase -name $STRAIN $GENOME
			RepeatModeler -threads $CPU -database $STRAIN -LTRStruct
			rsync -a RM_*/consensi.fa.classified $LIBRARY
			rsync -a RM_*/families-classified.stk $RMLIBFOLDER/$SPECIESNOSPACE.repeatmodeler.stk
			popd
		fi
		if [ -f $LIBRARY ]; then
	    		module load RepeatMasker
	    		RepeatMasker -e ncbi -xsmall -s -pa $CPU -lib $LIBRARY -dir $MASKDIR/${name} -gff $INDIR/${name}.fasta
		fi
	    fi
	    rsync -a $MASKDIR/${name}/${name}.fasta.masked $OUTNAME
	else
	    echo "Skipping ${name} as masked file already exists and is newer than current assembly file"
	fi
    done
done
