#!/usr/bin/bash -l
#SBATCH -p short -c 24 --mem 96gb --out logs/run_wgd.%a.log -a 1
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
  N=$1
fi
if [ -z $N ]; then
  echo "cannot run without a number provided either cmdline or --array in sbatch"
  exit
fi

module load wgd
SAMPLES=samples.csv
MAX=$(wc -l $SAMPLES | awk '{print $1}')
if [[ $N -gt $MAX ]]; then
	echo "N - $N - is too big, only $MAX lines in the file $SAMPLES"
	exit
fi
NAME=$(sed -n ${N}p $SAMPLES)
CDS=cds/$NAME.fa
GFF3=gff3/$NAME.gff3
SYN=wgd_syn
FAMDIR=wgd_dmd
KSDDIR=wgd_ksd
KS=$KSDDIR/$(basename $CDS).tsv.ks.tsv
FAMILIES=$FAMDIR/$(basename $CDS).tsv
mkdir -p $SYN $KSDDIR $FAMDIR
if [ ! -s $FAMILIES ]; then
	wgd dmd $CDS --nthreads $CPU --to_stop
fi
if [ ! -s $KS ]; then
	echo "cds=$CDS fam=$FAMILIES"
	wgd ksd $FAMILIES $CDS -t $SCRATCH -n $CPU --strip_gaps --to_stop
fi
mkdir -p wgd_syn/${NAME}
wgd syn -f mRNA -a ID $FAMILIES $GFF3 -ks $KS --outdir wgd_syn/${NAME} --minlen 100000
