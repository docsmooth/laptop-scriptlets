#!/usr/bin/env perl

# dump out which processes are using swap space and how much. Should work as a standard user.
# not super accurate due to how the Kernel reports shared library use, but it should
# give you an idea as to which processes were swapped at all
use strict;
use warnings;
use Data::Dumper;

my $debug=0;
my %pidhash;
my %swapsize;
my @fieldnames;
my %fieldname;
my $sep="\t";

#change these for non-Linux
my $swapfilename="status";
my $procdir="/proc";
my $pscmd="ps -ef";
my $swapmatch="VmSwap";

$debug && print "starting with path: ", $procdir, "##", $swapfilename, "\n";
open(my $PS, "-|", $pscmd);
while(<$PS>) {
    $debug && print "PS Line: $_";
    chomp;
    if (not @fieldnames) {
        @fieldnames=split(/\s+/, $_);
        %fieldname = map { $fieldnames[$_] => $_ } 0..$#fieldnames;
        $debug && print "capturing header line, found PID at: ", $fieldname{"PID"}, "\n";
        next;
    }
    my @fields=split(/\s+/, $_);
    my %entry= map { $fieldnames[$_] => $fields[$_] } 0..$#fieldnames;
    $debug && print Dumper(\%entry);
    $debug && print "storing entry at $fields[$fieldname{'PID'}]\n";
    $pidhash{$fields[$fieldname{'PID'}]} = \%entry;
}
close $PS;

opendir(my $PR, $procdir);
my @proclist= grep { /^[^.]/ && -f "$procdir/$_/$swapfilename" } readdir($PR);
closedir $PR;
foreach my $status (@proclist) {
    open(my $ST, "<", "$procdir/$status/$swapfilename") || next;
    while(my $line=<$ST>) {
        next unless $line=~/$swapmatch/;
        $line=~s/$swapmatch//;
        $line=~s/://;
        $line=~s/^\s*//;
        $debug && print "Reading swap $status: $line";
        $pidhash{$status}{"swap"}=$line;
        my @size=split(/\s+/, $line);
        $debug && print "saving size $size[0] with PID: $status\n";
        $swapsize{$size[0]}=$pidhash{$status};
    }
}
print "SIZE", $sep, "CMD", $sep, "OWNER", $sep, "PID\n";
foreach my $key (sort(keys(%swapsize))) {
    my $entry=$swapsize{$key};
    $debug && print "printing key $key\n";
    print $key, $sep, $entry->{"CMD"}, $sep, $entry->{"UID"}, $sep, $entry->{"PID"}, "\n";
}

