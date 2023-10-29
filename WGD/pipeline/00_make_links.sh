#!/usr/bin/bash -l
#SBATCH -p short
CDSdir=cds
GFFdir=gff3
mkdir -p $CDSdir $GFFdir
REF=/bigdata/stajichlab/shared/projects/Rhodotorula/Ref_genomes/annotation
for a in $(ls $REF/*/annotate_results/*cds-transcripts.fa)
do
	NAME=$(basename $a .cds-transcripts.fa | perl -p -e 's/sp\./sp/')
	GFF=$(echo $a | perl -p -e 's/\.cds-transcripts.fa/gff3/')
	ln -s $a $CDSdir/$NAME.fa
	ln -s $GFF $GFFdir/$NAME.gff3
	echo $NAME
done

DRAFT=/bigdata/stajichlab/shared/projects/Rhodotorula/ExtremeRhodotorula_DraftGenomes/annotation
for a in $(ls $DRAFT/*/predict_results/*cds-transcripts.fa)
do
        NAME=$(basename $a .cds-transcripts.fa | perl -p -e 's/sp\./sp/')
        GFF=$(echo $a | perl -p -e 's/\.cds-transcripts.fa/gff3/')
        ln -s $a $CDSdir/$NAME.fa
        ln -s $GFF $GFFdir/$NAME.gff3
        echo $NAME
done
