#!/usr/bin/perl

use strict;
use warnings;

my $file=shift;
my $debug=0;

# these funcitons from: https://hybby.wordpress.com/2013/02/27/389/
sub dec2bin {
  my $str = unpack("B32", pack("N", shift));
  return $str;
}
 
sub netmask2cidr {
    my $mask = shift;
    my @octet = split (/\./, $mask);
    my @bits;
    my $binmask;
    my $binoct;
    my $bitcount=0;
 
    foreach (@octet) {
      $binoct = dec2bin($_);
      $binmask = $binmask . substr $binoct, -8;
    }
 
    # let's count the 1s
    @bits = split (//,$binmask);
    foreach (@bits) {
      if ($_ eq "1") {
        $bitcount++;
      }
    }
 
    return $bitcount;
}

#first determine local links when not on VPN, so we can filter out those routes

open(RO, "ip route |") || die "can't run ip route: $!";
my @routes=qw(:: 224.0.0.0 127.0.0.0 255.255.255.255);
while (<RO>) {
    next unless (/scope link/);
    chomp;
    $debug && print "checking '$_'...\n";
    /^([0-9.]+)\//;
    if ($1) {
        push(@routes, $1);
        $debug && print "added '$1' to \@routes.\n";
    }
}

open(FH, "<$file") || die "can't open $file: $!";
my $i=0;
my $skiproutes=join("|", @routes);
$debug && print "skiproutes is now ($skiproutes)\n";
while (<FH>) {
    chomp;
    next unless (/On-link/); 
    if (/($skiproutes)/) {
        next; 
    }; 
    if (/^\s*On-link\s*$/) { 
        next; 
    }; 
    $debug && print "rewriting: $_\n";
    my @fields=split(/\s+/, $_);
    # fields:
    # empty network netmask GW interface metric
    if ($fields[3]=~/On-link/) {
        $fields[3]="0.0.0.0";
    }
    $i++; 
    print "route$i=".$fields[1]."/".netmask2cidr($fields[2]).",".$fields[3].",".$fields[5]."\n";
}
