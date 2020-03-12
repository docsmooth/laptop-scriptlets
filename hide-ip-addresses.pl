#!/usr/bin/env perl

#sed -re 's/(192\.168|10\.[[:alnum:]]*)\.[[:alnum:]]*\./x.x.x./g' -e 's/:1700:5650:16a8:[[:alnum:]]*:[[:alnum:]]*:[[:alnum:]]/:x:/g' -e 's/:[[:alnum:]]{2}:[[:alnum:]]{2}:[[:alnum:]]{2}:/:xx:xx:xx:/g'

sub clearIP
{
    my $x=shift;
    $x=~s/(192\.168|172\.(16|17|18|19|30|31|32|2[0-9])|10\.\d{1,3})\.\d{1,3}(\.\d{1,3})/172.16.x\3/g;
    $x=~s/([a-f0-9]{1,4}):([a-f0-9]{1,4}:){3,6}([a-f0-9]{1,4})/\1::x:x:\3/g;
    return $x
}
if (-t STDIN) {
    my $y=clearIP shift;
    print "$y\n";
} else {
    while (<>) {
        print clearIP $_;
    }
}
