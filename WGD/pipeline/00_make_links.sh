#!/usr/bin/bash -l
#SBATCH -p short
CDSdir=cds
GFFdir=gff3
mkdir -p $CDSdir $GFFdir
REF=/bigdata/stajichlab/shared/projects/Rhodotorula/Ref_genomes/annotation
DRAFT=/bigdata/stajichlab/shared/projects/Rhodotorula/ExtremeRhodotorula_DraftGenomes/annotation
# REF GENOMES WILL TAKE PRECEDENCE
for a in $(ls $REF/*/annotate_results/*cds-transcripts.fa $DRAFT/*/predict_results/*cds-transcripts.fa)
do
	NAME=$(basename $a .cds-transcripts.fa | perl -p -e 's/sp\./sp/')
	DNAME=`dirname $(dirname $a)`
	DNAME=$(basename $DNAME)
	#echo $DNAME
	#echo $a | grep -v Ref
	if [[ -z $(echo $a | grep Ref) && ! -z $(ls $REF/*/annotate_results/$(basename $a)) ]]; then
		#echo "skipping draft genome $NAME as a REF exists"
		continue
	fi
	
	if [ ! -f $CDSdir/$NAME.fa ]; then
		ln -s $a $CDSdir/$NAME.fa
	fi
	GFF=$(echo $a | perl -p -e 's/\.cds-transcripts.fa/.gff3/')
	if [ ! -f $GFFdir/$NAME.gff3 ]; then
		ln -s $GFF $GFFdir/$NAME.gff3
	fi
	echo $NAME
done | sort | uniq

#for a in $(ls $DRAFT/*/predict_results/*cds-transcripts.fa)
#do
#        NAME=$(basename $a .cds-transcripts.fa | perl -p -e 's/sp\./sp/')
#        GFF=$(echo $a | perl -p -e 's/\.cds-transcripts.fa/gff3/')
#        ln -s $a $CDSdir/$NAME.fa
#        ln -s $GFF $GFFdir/$NAME.gff3
#        echo $NAME
#done
