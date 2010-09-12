#!/usr/bin/perl -w

# Info: Make a csv index file for Parish maps downloaded into parishmaps_html
# Author: Andrew Harvey (http://andrewharvey4.wordpress.com/)
# Date: 
#
# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

# Usage: ../make_index_PH.pl *.html > ../parish_index.csv

use strict;
use HTML::TableExtract;

print "mapid,county,parish,barcode,edition,sheet,year,cd_title,image_id\n";

foreach my $file (@ARGV) {
    open IN, "$file" or die;
    my $html_string = join("\n", <IN>);

    $file =~ /mid=(\d*)/;
    my $mapid = $1;

    my $parish;
    my $county;


    #get the Run Name and number
    if ($html_string =~ /<td>Parish:<\/td><td><b>([^<]*)<\/b><\/td><\/tr><tr><td>County:<\/td><td><b>([^<]*)<\/b><\/td>/) {
        $parish = $1;
        $county = $2;
        #print "$county,$parish\n";
    }


    #now look for the table with the sheet details

    my $te = HTML::TableExtract->new( headers => ['Barcode', 'Edition', 'Sheet', 'Year', 'CD Title', 'Image ID'] );
    $te->parse($html_string);

    foreach my $ts ($te->tables){
        foreach my $row ($ts->rows) {
            my $row_text = join(',', @$row);
            $row_text =~ s/\n//g;
            print "$mapid,$county,$parish,", $row_text, "\n";
        }
    }
    close IN;
}

