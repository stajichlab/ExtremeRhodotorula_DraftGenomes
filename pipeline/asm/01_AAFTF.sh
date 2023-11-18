#!/bin/bash -l
#SBATCH -p batch -N 1 -n 1 -c 24 --mem 64gb --out logs/AAFTF.%a.log

# requires AAFTF 0.3.1 or later for full support of fastp options used

MEM=64
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

FASTQ=input
SAMPLEFILE=samples.csv
ASM=asm/AAFTF
WORKDIR=$SCRATCH
WORKDIR=working_AAFTF
PHYLUM=Basidiomycota
mkdir -p $ASM $WORKDIR
if [ -z $CPU ]; then
    CPU=1
fi
IFS=, # set the delimiter to be ,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read ID BASE SRA SPECIES STRAIN LOCUSTAG BIOPROJECT BIOSAMPLE NOTES
do
    if [[ "$NOTES" == "Too Low" ]]; then
	echo "skipping $N ($ID) as it is too low coverage ($NOTES)"
	continue
    fi
    module load AAFTF
    module load fastp
    ASMFILE=$ASM/${ID}.spades.fasta
    VECCLEAN=$ASM/${ID}.vecscreen.fasta
    PURGE=$ASM/${ID}.sourpurge.fasta
    CLEANDUP=$ASM/${ID}.rmdup.fasta
    POLISHED=$ASM/${ID}.polished.fasta
    SORTED=$ASM/${ID}.sorted.fasta
    STATS=$ASM/${ID}.sorted.stats.txt

    LEFTIN=$WORKDIR/${ID}_all_R1.fq.gz
    RIGHTIN=$WORKDIR/${ID}_all_R2.fq.gz
	if [[ -s $SORTED ]]; then
		OLDER=1
		for BASEPATTERN in $(echo $BASE | perl -p -e 's/\;/,/g');
		do
			L=$FASTQ/${BASEPATTERN}_1.fastq.gz
			R=$FASTQ/${BASEPATTERN}_2.fastq.gz
			if [ ! -f $L ]; then
				B=$(echo -n $BASEPATTERN | perl -p -e 's/_R\[12\]\S+//')
				L=$FASTQ/${B}_R1_001.fastq.gz
				R=$FASTQ/${B}_R2_001.fastq.gz
				if [ ! -f $L ]; then
					echo "no $LEFTIN file for $ID/$B in $FASTQ dir"
					exit
				fi
				if [[ $L -nt $SORTED ]]; then
					OLDER=0
					break
				fi
			fi
		done
		if [[ $OLDER == 1 ]]; then
			echo "skipping $ID $STRAIN --> $SORTED already exists and all FASTQ are older"
			exit
		fi
	fi
    if [ ! -f $LEFTIN ]; then
		for BASEPATTERN in $(echo $BASE | perl -p -e 's/\;/,/g');
		do
			L=$FASTQ/${BASEPATTERN}_1.fastq.gz
			R=$FASTQ/${BASEPATTERN}_2.fastq.gz
			if [ ! -f $L ]; then
				B=$(echo -n $BASEPATTERN | perl -p -e 's/_R\[12\]\S+//')
				L=$FASTQ/${B}_R1_001.fastq.gz
				R=$FASTQ/${B}_R2_001.fastq.gz
				if [ ! -f $L ]; then
					echo "no $LEFTIN file for $ID/$B in $FASTQ dir"
					exit
				fi
			fi
			echo "concatenating $L to $LEFTIN"
			echo "concatenating $R to $RIGHTIN"
			cat $L >> $LEFTIN
			cat $R >> $RIGHTIN
		done
    fi
    LEFTTRIM=$WORKDIR/${ID}_1P.fastq.gz
    RIGHTTRIM=$WORKDIR/${ID}_2P.fastq.gz
    MERGETRIM=$WORKDIR/${ID}_fastp_MG.fastq.gz

    # these are final processed files for assembly
    LEFT=$WORKDIR/${ID}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${ID}_filtered_2.fastq.gz
    MERGED=$WORKDIR/${ID}_filtered_U.fastq.gz

    echo "$BASE $ID $STRAIN"
    echo "$LEFTIN $RIGHTIN $LEFTTRIM $RIGHTTRIM"

    
    if [ ! -f $LEFT ]; then
		if [ ! -f $LEFTTRIM ]; then
			AAFTF trim --method fastp --dedup --merge --memory $MEM --left $LEFTIN --right $RIGHTIN -c $CPU -o $WORKDIR/${ID}_fastp
			AAFTF trim --method fastp --cutright -c $CPU --memory $MEM --left $WORKDIR/${ID}_fastp_1P.fastq.gz --right $WORKDIR/${ID}_fastp_2P.fastq.gz -o $WORKDIR/${ID}_fastp2
			AAFTF trim --method bbduk -c $CPU --memory $MEM --left $WORKDIR/${ID}_fastp2_1P.fastq.gz --right $WORKDIR/${ID}_fastp2_2P.fastq.gz -o $WORKDIR/${ID}
		fi
		AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${ID} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
		AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${ID} --left $MERGETRIM --aligner bbduk
		if [ -f $LEFT ]; then
			rm -f $LEFTTRIM $RIGHTTRIM $WORKDIR/${ID}_fastp* 
			echo "found $LEFT"
		else
			echo "did not create left file ($LEFT $RIGHT)"
			exit
		fi
    fi
    if [ ! -f $ASMFILE ]; then # can skip we already have made an assembly
	AAFTF assemble -c $CPU --left $LEFT --right $RIGHT --merged $MERGED --memory $MEM \
	      -o $ASMFILE -w $WORKDIR/spades_${ID}
	
	#if [ -s $ASMFILE ]; then
	#    rm -rf $WORKDIR/spades_${ID}/K?? $WORKDIR/spades_${ID}/tmp $WORKDIR/spades_${ID}/K???
	#    rm -rf $WORKDIR/spades_${ID}
	#fi
	
	if [ ! -f $ASMFILE ]; then
	    echo "SPADES must have failed, exiting"
	    tail -n 100 $WORKDIR/spades_${ID}/spades.log
	    exit
	fi
    fi
    
    if [[ ! -f $VECCLEAN && ! -f $VECCLEAN.gz ]]; then
	AAFTF fcs_screen -i $ASMFILE -o $VECCLEAN.fcs_screen
	AAFTF vecscreen -i $VECCLEAN.fcs_screen -c $CPU -o $VECCLEAN
    fi
    if [[ ! -f $PURGE && ! -f $PURGE.gz ]]; then
	AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM 
	# let's not remove based on coverage for now this maybe too agressive
	#--left $LEFT --right $RIGHT
	pigz $VECCLEAN
	pigz $VECCLEAN.fcs_screen 
    fi
    
    if [[ ! -f $CLEANDUP && ! -f $CLEANDUP.gz ]]; then
    	AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 500
	pigz $PURGE 
    fi
    
    if [[ ! -f $POLISHED && ! -f $POLISHED.gz ]]; then
	if [ ! -f $CLEANDUP ]; then
	    gunzip $CLEANDUP
	fi
    	AAFTF polish --method polca -i $CLEANDUP -o $POLISHED -c $CPU --left $LEFT  --right $RIGHT --mem $MEM
	pigz $CLEANDUP
    fi
    
    if [[ ! -f $POLISHED && ! -f $POLISHED.gz ]]; then
    	echo "Error running Pilon, did not create file. Exiting"
    	exit
    fi
    
    if [ ! -f $SORTED ]; then
		AAFTF sort -i $POLISHED -o $SORTED
		pigz $POLISHED
    fi
    
    if [ ! -f $STATS ]; then
		AAFTF assess -i $SORTED -r $STATS
    fi
done
