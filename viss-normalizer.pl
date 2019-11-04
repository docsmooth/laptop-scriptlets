#!/usr/bin/perl
#
#
use strict;
use warnings;

my %globalSeparators;
my $filenum=0;
my $prefix="format";

while(<>) {
	chomp;
	my @fields=split(/\b/, $_);
	my @separatorGuesses=grep ! /[a-zA-Z0-9]/, @fields;
    my %seps;
	foreach my $sep (@separatorGuesses) {
        if (not exists($seps{$sep})) { 
            $seps{$sep}=1;
        } else {
            $seps{$sep}++;
        }
    }
    my @topsep=sort { $seps{$a} <=> $seps{$b} } keys %seps;
    if (not exists($globalSeparators{$topsep[0]})) {
        if ( open (my $fh, ">", $prefix.$filenum.".txt")) {
            $globalSeparators{$topsep[0]}->{"fh"}=$fh;
        } else {
            die "Could not open $prefix".$filenum.".txt to write!!";
        }
        $globalSeparators{$topsep[0]}->{"filename"}=$prefix.$filenum.".txt";
        $filenum++;
    }

	print { $globalSeparators{$topsep[0]}->{fh}} ("$_\n");
}
foreach my $entry (keys(%globalSeparators)) {
    close $globalSeparators{$entry}->{fh};
}
