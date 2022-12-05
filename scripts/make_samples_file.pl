#!/usr/bin/env perl
use strict;
use warnings;

my $in = 'read_files.txt';
my $out = 'samples.csv';

open(my $fh => $in) || die "cannot open $in: $!";
open(my $ofh => ">$out") || die "cannot open $out: $!";
print $ofh join(",",qw(Strain FileBase Species LocusTag)),"\n";
while(<$fh>) {
    chomp;
    my $name = $_;
    if ( /^(P\d+\-[A-Z]\d+\-)(\S+)/ ) {		
	my $strain = $2;
	$strain =~ s/x(\d+)/.$1/;
	print $ofh join(",", $strain,sprintf("%s_R[12].fastq.bz2",$name),"",""),"\n";
    } else {
	warn("cannot parse $_\n");
    }
}
