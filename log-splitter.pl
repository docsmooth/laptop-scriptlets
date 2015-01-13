#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

sub safeRegex($) {
    my $line = shift || die "no line to clean up for regex matching!\n";
    my $regex = $line;
    $regex=~s/([\*\[\]\-\(\)\.\?\/\^\\])/\\$1/g;
#    logDebug("Cleaned up '$line' as '$regex'");
    return $regex;
}

sub usage {
    print <<EOF
log-splitter version 0.2
This tool reads in a file (filename), and prints out log-<header>#.txt files
The contents of each of those files is from the "header" value (inclusive) until
the next "separator" value (excluded).
If multiple headers are found inside a "section", the subsequent headers are
treated as normal text.
If a new header is found after a separator, a new file is opened.

Options:
--help - get help
--filename "file" - the file to read in
--header "text" - the text that marks "start reading"
--separator "text" - the text that marks new sections

EOF
}

Getopt::Long::Configure('no_ignore_case', 'no_auto_abbrev') || die "Can't use getopt::long !! - $!";                                                                                                                                  

my $opt = { filename => "tmp/pbis-support.log",
    separator => "#############################",
    header => "ps output",
};

my $ok = GetOptions($opt,
    'help|h|?',
    'separator|s=s',
    'header|h=s',
    'filename|f=s',
);
my $more = shift @ARGV;
my $errors;
if ($opt->{help} ) {
    exit usage();
}
if (not $ok or $more) {
    die "Invalid Options chosen, please run with '--help' to see available options";
}

my $filename=$opt->{filename};
my $seen=0;

my $separator=$opt->{separator};
my $header = $opt->{header};
my $outFH;
my $outfile = $filename.".".$header;
my $i=0;
$outfile=~s/[^a-zA-Z0-9\-]*//g;
$header=safeRegex($header);

open(FH, "<$filename") || die "can't open $filename - $!";
while(<FH>) { 
    if (/$separator/ && $seen == 1) {
        $seen=0;
        $i++;
        if ($outFH) {
            close $outFH;
            undef $outFH;
        }
    }; 
    if (/$header/) { 
        $seen=1; 
    }; 
    if ($seen) {
        unless ($outFH) {
            open($outFH, ">", "log-".$outfile.$i.".txt") || die "can't open $outfile"."$i - $!";
        }
        print $outFH $_;
    }
}
