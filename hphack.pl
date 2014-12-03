#!/usr/bin/perl -w 
#File name: lcd.pjl.pl 
#From http://www.Irongeek.com Irongeek@irongeek.com
#Script to set LCD Display an HP JetDirect printer 
#Syntax: ./lcd.pjl.pl <ip-of-jetdirect> "Some Message" 
use IO::Socket; 

$ip = shift; 
$lcdtext = join(" ", @ARGV); 
my $sock = new IO::Socket::INET ( 
    PeerAddr => $ip, 
    PeerPort => '9100', 
    Proto => 'tcp', 
    ); 
die "Could not create socket, Monkey boy! $!\n" unless $sock; 
print $sock "\x1b\%-12345X\@PJL RDYMSG DISPLAY = \"$lcdtext\"\n"; 
print $sock "\x1b\%-12345X\n"; 
close($sock);