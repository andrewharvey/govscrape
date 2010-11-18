#!/usr/bin/perl -w

# Info: 
# Author: Andrew Harvey (http://andrewharvey4.wordpress.com/)
# Date: 
#
# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

# Usage: ./

use strict;

while (my $line = <STDIN>) {
    chomp $line;
    #convert http://www.nla.gov.au/apps/cdview?pi=nla.map-rm994-s5-sd
    #to http://www.nla.gov.au/nla.map/rm/009/94/nla.map-rm00994-s005-sd.sid
    #in geneneral we should have letters/3 digits/2 digits/...-rm5digits-(s3digits)optionally
    my ($start, $args) = split /\?/, $line;
    if ($args =~ /pi=nla.map-([a-z]*)([0-9]*)([a-z]?)(-[a-z]?[0-9]+[a-z]?)?/) { #could require -sd at the end
        my $code = $1; #rm or nk
        my $number = $2;
        my $number_suffix = $3;
        my $part = $4; #optional

        my $full_number = sprintf("%05d",$number); #make sure number is 5 digits long
        my $num_part1 = substr $full_number, 0, 3;
        my $num_part2 = substr $full_number, 3, 2;

        $num_part2 .= $number_suffix;
        $full_number .= $number_suffix;

        my $full_part = '';
        if (defined $part) {
            $part =~ /-([a-z]?)([0-9]*)([a-z]?)/;
            $full_part = "-".$1.sprintf("%03d", $2).$3;
        }

        my $full_url = "http://www.nla.gov.au/nla.map/$code/$num_part1/$num_part2/nla.map-$code$full_number$full_part-sd.sid";

        print $full_url."\n";
    }else{
        print STDERR "$line\n"
    }
}

exit;
