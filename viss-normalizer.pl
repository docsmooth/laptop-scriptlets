#!/usr/bin/perl
#
#
use strict;
use warnings;
while(<>) {
    chomp;
    my @x=split(/\b/, $_);
    print join("\t", @x), "\n";
}
