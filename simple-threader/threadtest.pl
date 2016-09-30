#!/usr/bin/perl
#
#A simple threading tool for running multiple bash/dash scripts simultaneously, with
#slightly-more-sane printing.  We capture all return from the shell script in the thread
#then only print it when we join the thread upon it completing it's job.
#
#Probably unsafe for scripts with large output, but probably safe for short jobs.
#Includes an example job.  
#
#
#Defaults to up to 20 threads, adds "-1" to the end of the queue (which it builds from STDIN)
# - the "-1" is the "end" marker

use strict;
use warnings;

use threads;
use Thread::Queue;

my $j=0;
my ($i, @returnData, $error);
my (@networks, @thr);

my @servers;
while (<>) {
    chomp;
    push(@servers, $_);
}

my $q=new Thread::Queue;
$q->enqueue(@servers);

for ($i=0;$i<20;$i++) {
    $q->enqueue("-1");
    print "queuing $i...\n";
    $thr[$i]=threads->new(\&runremotejob);
}

foreach ($i=0;$i<@thr;$i++) {
    print $thr[$i]->join(), "\n";
}

#while (@returnData) {
#    print $_, "\n";
#}


sub runremotejob() {
    my $server;
    my $return="";
    while (($server=$q->dequeue) ne "-1") {
        $return.=`./dojob.sh`;
    }
    return $return;
}

