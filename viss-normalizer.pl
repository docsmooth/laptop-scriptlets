#!/usr/bin/perl
#
#
use strict;
use warnings;
while(<>) {
    chomp;
    my @x=split(/\b/, $_);
    my @y=grep /[a-zA-Z0-9]/, @x;
    print join("\t", @y), "\n";
}
