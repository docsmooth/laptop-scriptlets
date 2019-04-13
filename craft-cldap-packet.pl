#!/usr/bin/perl
#
#
use strict;
use warnings;

	my $domain = shift || die "No domain passed to cldap data sub!!";
	my @hex = unpack("H*", $domain);
	my $data="a3180409446e73446f6d61696e04".sprintf("%02x", length($domain)).join("", @hex)."a30d04054e74566572040406000080300a04084e65746c6f676f6e";
	$data="04000a01000a010002010002013c010100a0".sprintf("%02x", length($data)/2-12).$data;
	$data="02010263".sprintf("%02x", length($data)/2).$data;
	$data="30".sprintf("%02x", length($data)/2).$data;
	print $data, "\n";
