#!/usr/bin/perl -w

# Info: Make a csv index file for Pastor maps downloaded into pastormaps_html
# Author: Andrew Harvey (http://andrewharvey4.wordpress.com/)
# Date: 
#
# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

# Usage: ../make_index_PL.pl *.html > ../parstor_index.csv

use strict;
use HTML::TableExtract;

print "mapid,run_number,run_name,barcode,map_no,sheet,division,cd_title,image_id\n";

foreach my $file (@ARGV) {
    open IN, "$file" or die;
    my $html_string = join("\n", <IN>);

    $file =~ /mid=(\d*)/;
    my $mapid = $1;

    my $run_name;
    my $run_number;


    #get the Run Name and number
    if ($html_string =~ /<td>Run Name:<\/td><td><b>([^<]*)<\/b><\/td><\/tr><tr><td>Run Number:<\/td><td><b>([^<]*)<\/b><\/td>/) {
        $run_name = $1;
        $run_number = $2;
        #print "$run_number,$run_name\n";
    }


    #now look for the table with the sheet details

    my $te = HTML::TableExtract->new( headers => ['Barcode', 'Map No', 'Sheet', 'Division', 'CD Title', 'Image ID'] );
    $te->parse($html_string);

    foreach my $ts ($te->tables){
        foreach my $row ($ts->rows) {
            my $row_text = join(',', @$row);
            $row_text =~ s/\n//g;
            print "$mapid,$run_number,$run_name,", $row_text, "\n";
        }
    }
    close IN;
}

