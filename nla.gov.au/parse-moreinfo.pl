#!/usr/bin/perl -w

# Info: Parses the NLA more information HTML pages. Pages like this one,
#       http://www.nla.gov.au/cdview/nla.map-rm1078&mode=moreinfo
# Author: Andrew Harvey (http://andrewharvey4.wordpress.com/)
# Date: 01 Oct 2010
#
# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

# Usage: ./parse-moreinfo.pl [html files..]

use strict;

use HTML::TreeBuilder;
use File::Basename;

my $DATABASE_FILE = "moreinfo-db.tsv";
my $USE_DB_DERIVED = 1;

my @crown_creator = (
    "New South Wales. Dept. of Lands.",
    "New South Wales. Surveyor-General.",
    "New South Wales. Postmaster-General's Dept.",

    "Queensland. Chief Engineer's Office.",
    "Queensland. Commissioner for Railways.",
    "Queensland. Government Engraving and Lithographic Office.",
    "Queensland. Railway Dept.",
    "Queensland Railways.",
    "Queensland Railways. Chief Engineer's Office.",
    "Queensland. Survey Dept.",
    "Queensland. Survey Office.",
    "Queensland. Surveyor General's Dept.",
    "Queensland. Surveyor General's Office.",
    "Queensland. Surveyor-General's Office.",
    "Queensland. Water Supply Dept.",

    "South Australia. Engineer-in-Chief's Dept.",
    "South Australia. Engineer-in-Chief's Office.",
    "South Australia. Government Printer.",
    "South Australia. Surveyor General's Office.",
    "South Australia. Surveyor-General's Office",
    "South Australia. Surveyor-General's Office.",

    "Tasmania. Dept. of Lands and Works.",
    "Tasmania. Dept. of Lands and Works. Survey Office.",
    "Tasmania. Dept. of Mines.",
    "Tasmania. Dept. of Surveys.",
    "Tasmania. Lands Dept.",
    "Tasmanian Government Tourist Bureau.",
    "Tasmania. Survey Dept.",
    "Tasmania. Surveyor General's Office.",

    "Victoria. Board of Land and Works.",
    "Victoria. Colonial Engineer's Dept.",
    "Victoria. Dept. of Crown Lands and Surve",
    "Victoria. Dept. of Crown Lands and Survey",
    "Victoria. Dept. of Crown Lands and Survey.",
    "Victoria. Dept. of Lands and Survey.",
    "Victoria. Dept. of Mines.",
    "Victoria. Mines Dept.",
    "Victoria. Office of the General Superintendent of Electric Telegraph.",
    "Victoria. Public Lands Office.",
    "Victoria. Surveyor-General.",
    "Victoria. Surveyor General's Office",
    "Victoria. Surveyor General's Office.",
    "Victoria. Yarra Floods Board.",

    "Western Australia. Dept. of Lands and Surveys.",
    "Western Australia. Dept. of Mines.",
    "Western Australian Government Railways Commission.",
    "Western Australia. Surveyor General's Division.",
    "Western Australia. Surveyor General's Office.",

    "Australia. Army. Divisional Artillery Headquarters.",
    "Australia. Dept. of Home and Territories. Lands and Surveys Branch.",
    "Australia. Dept. of Home and Territories. Northern Territory Branch.",
    "Australia. Dept. of the Interior.",
    "Australia. Division of National Mapping.",
    "Australian Survey Office. A.C.T. Branch.",
    "Australia. Royal Australian Air Force.",
    "Australia. Royal Australian Navy. Hydrographic Service."
);

#currently you need to set these manually.
my @dbheadings = ('Creator', 'Title', 'Scale', 'Publisher', 'Date', 'Material Type', 'Physical Description', 'Notes', 'Subjects', 'Call Number', 'Amicus Number', 'Citation');

#strip leading and trailing whitespace
sub sltw {
    for (@_){ s/^\s*//}
    for (@_){ s/\s*$//}
}

sub printinfohash {
    my $basename = shift;
    my $p = shift;
    my %h = %$p;

    print DB $basename . "\t";

    foreach my $k (@dbheadings) {
        if (exists $h{$k}) {
            print DB $h{$k}."\t";
        }else{
            print DB "\t"; #if the key is not in the hash then we should just get the \t
            print STDERR "    $k does not exist\n";
        }
        
    }

    if ($USE_DB_DERIVED) { #optionally we can print some more derived info from the values we already have
        my $crown;
        my $creator_died;
        my $creator_born;
        #extract creator information
        if (exists $h{'Creator'}) {
            my $creator = $h{'Creator'};

            #crown copyright?
            if ($creator ~~ @crown_creator) {
                print DB "true\t";
                $crown = 'true';
            }else{
                print DB "false\t";
            }

            #creator lifespan
            $creator =~ tr/[^\d\-\?]//; #remove non-digits (but leave in - and ?)
            $creator =~ /(\d*)\??\-(\d*)\??/;
            print DB $1."\t";
            print DB $2."\t";
            $creator_born = $1;
            $creator_died = $2;
            
            $creator =~ /\d*(\??)\-\d*(\??)/;
            print DB $1."\t";
            print DB $2."\t";

            $creator_born = undef if ($1 eq '?'); #if it is uncertain, don't use it
            $creator_died = undef if ($2 eq '?'); #if it is uncertain, don't use it
        }else{
            print DB "\t\t\t\t\t";
        }
        
        #extract scale information
        if (exists $h{'Scale'}) {
            my $scale = $h{'Scale'};
            #Scale [ca. 1:18 200].
            my $scale_not_given = 'f';
            my $ca = 'f'; #is scale approximate?
            if ($scale =~ /(Scale not given.)|(Not drawn to scale.)|(Scale indeterminable.)|(Various scales.)/) {
                $scale_not_given = 't';
            }else{
                $scale =~ tr/,//;
                $scale =~ tr/ //; #remove spaces, we should be able to parse without them, and it should make the parse more robust
        #        $scale =~ /Scale \[(ca\.)? ?(\d: ?[\d,]*)?\]\.?\s*(.*)/
                $scale =~ /(\d:\d)/;
                my $first_found_scale = $1;
                $ca = 't' if ($scale =~ /ca[\. ]/);
            }
        }

        if (exists $h{'Date'}) {
            my $date = $h{'Date'};
            my $end_date;
            if ($date !~ /-/) { #just one date
                $date =~ /^(\d{4})$/; #only take if there is no ambiguity
                $date = $1;
                $end_date = $date;
                print DB $date."\t";
                print DB $date."\t";
            }else{ #date is a range
                $date =~ /(\d{4})-(\d{4})/;
                print DB $1."\t";
                print DB $2."\t";
                $end_date = $2;
            }

            my $public_domain;

            if ($crown) {
                $public_domain = $end_date + 50 if (defined $end_date);
            }else{
                if (defined $creator_died) {
                    if ($creator_died < 1955) {
                        $public_domain = $creator_died + 50;
                    }else{
                        $public_domain = $creator_died + 70;
                    }
                }elsif (defined $creator_born) {
                    $public_domain = $creator_born + 110 + 70; #i think it is safe to assume this
                }
            }

            if (defined $public_domain) {
                print DB $public_domain."\t";
            }else{
                print DB "\t";
            }
            
        }else{
            print DB "\t\t\t";
        }
    }

    print DB "\n";
}

#open the database file that we save everything to
die "$DATABASE_FILE already exists. Aborting.\n" if -e "$DATABASE_FILE";

open DB, ">$DATABASE_FILE";

#print the heading line
print DB "file\t";
print DB join "\t", @dbheadings;
if ($USE_DB_DERIVED) {
    print DB "\tcrown\tcreator_born\tcreator_died\tcreator_born_aprox\tcreator_died_aprox\tstart_date\tend_date\tpublic_domain";
}
print DB "\n";

#for each file we will also create a tsv file for just that HTML,
#along with the db file which contains the details of all the files
foreach my $file (@ARGV) {
    open HTML, "$file" or next;
    
    print STDERR "$file.tsv exists, overwriting it.\n"  if -e "$file.tsv";

    open TSV, ">$file.tsv";

    print "$file:\n";

    my $html = join "\n", <HTML>; #read the whole file into $html
    
    my $element;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html); $tree->eof;
    $tree->elementify();

    #find the table that lists all the data
    my @table = $tree->look_down('_tag', 'table',
                                 'class', 'text-content');

    if (@table > 0) {
        my @rows = $table[0]->look_down('_tag','tr');

        my %infohash;

        foreach my $row (@rows) {
            if (defined $row) {
                my ($key, $value) = $row->look_down('_tag', 'td');
                if (defined $key && defined $value) {
                    my $key_text = $key->as_text();
                    my $value_text = $value->as_text(); #perhaps we want to keep HTML for the notes entry... at least that would then ensure we don't loose the <br>.
                    
                    chomp $key_text;
                    chomp $value_text;

                    #strip leading and trailing whitespace
                    sltw $key_text;
                    sltw $value_text;

                    #remove the : at the end of the key
                    $/ = ':';
                    chomp $key_text;
                    $/ = ''; #reset it

                    #remove any tabs (to make using tab separated values format easier)
                    $key_text =~ tr/\t//;
                    $value_text =~ tr/\t//;

                    $key_text = "Citation" if ($key_text eq "To cite this item use");

                    $infohash{$key_text} = $value_text;
                   
                    print TSV $key_text . "\t" . $value_text . "\n";
                }
            }
        }
        my $base = basename($file, ('.html'));
        printinfohash($base, \%infohash);
    }else{
        print STDERR "Table not found in $file\n";
    }
    
    close HTML;
    close TSV;
}

close DB;

