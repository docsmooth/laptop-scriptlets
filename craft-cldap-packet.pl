#!/usr/bin/perl
#
#
use strict;
use warnings;

# to use this:
# 1) get the DNS domain name you're interested in, say "haha.local"
# 2) dig SRV _ldap._tcp.dc._msdcs.haha.local +short
#      This gives you a list of all the DCs
# 3) run ./craft-cldap-packet.pl haha.loca
# 4) perl -e 'print pack("H*", "*output from above*");' | nc -u *DC from line 2* 389
#
# Why doesn't this script do it all?  Because copy/paste is more portable, and nc is installed in a lot more places, and the point of this was just the 7 lines below.
#
# This is all taken from:
# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/7fcdce70-5205-44d6-9c3a-260e616a2f04  (DNS based discovery)
# and 
# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/895a7744-aff3-4f64-bcfa-f8c05915d2e9 (LDAP Ping search)
# and
# NETLOGON_SAM_LOGON structures and constants:
# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/b3006506-4338-45ef-ac52-1e7d5c9c46e9

	my $domain = shift || die "No domain passed to cldap data sub!!";
	my @hex = unpack("H*", $domain);
	my $data="a3180409446e73446f6d61696e04".sprintf("%02x", length($domain)).join("", @hex)."a30d04054e74566572040406000080300a04084e65746c6f676f6e";
	$data="04000a01000a010002010002013c010100a0".sprintf("%02x", length($data)/2-12).$data;
	$data="02010263".sprintf("%02x", length($data)/2).$data;
	$data="30".sprintf("%02x", length($data)/2).$data;
	print $data, "\n";
