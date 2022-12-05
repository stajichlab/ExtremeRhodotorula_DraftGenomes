#!/bin/bash -l
#SBATCH -p short --ntasks 48 --nodes 1 --mem 48G --out logs/annotate_mask.%a.log

module unload miniconda3

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
MASKDIR=RepeatMasker_run
SAMPLES=samples.csv
RMLIBFOLDER=lib/repeat_library
mkdir -p $RMLIBFOLDER
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
tail -n +2 $SAMPLES | sed -n ${N}p | while read ID BASE SPECIES STRAIN LOCUSTAG TYPESTRAIN
do
    name=$BASE
    SPECIESNOSPACE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/[\(\)\s]+/_/g')

    for type in AAFTF shovill
    do
	name=$ID.$type
	if [ ! -f $INDIR/${name}.fasta ]; then
		echo "Cannot find $name.fasta in $INDIR - may not have been run yet"
		exit
	fi
	if [ ! -s $INDIR/${name}.masked.fasta ]; then
	    mkdir -p $MASKDIR/${name}
	    GENOME=$(realpath $INDIR/${name}.fasta)
	    if [ ! -f $MASKDIR/${name}/${name}.fasta.masked ]; then
		LIBRARY=$RMLIBFOLDER/$SPECIESNOSPACE.repeatmodeler.lib
		if [ ! -f $LIBRARY ]; then
			module load RepeatModeler
			pushd $MASKDIR/${name}
			BuildDatabase -name $ID $GENOME
			RepeatModeler -pa $CPU -database $ID -LTRStruct
			rsync -a RM_*/consensi.fa.classified $LIBRARY
			rsync -a RM_*/families-classified.stk $RMLIBFOLDER/$SPECIESNOSPACE.repeatmodeler.stk
			popd
		fi
		if [ -f $LIBRARY ]; then
	    		module load RepeatMasker
	    		RepeatMasker -e ncbi -xsmall -s -pa $CPU -lib $LIBRARY -dir $MASKDIR/${name} -gff $INDIR/${name}.fasta
		fi
	    fi
	    rsync -a $MASKDIR/${name}/${name}.fasta.masked $INDIR/${name}.masked.fasta
	else
	    echo "Skipping ${name} as masked file already exists"
	fi
    done
done
