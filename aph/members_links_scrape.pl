#!/usr/bin/perl

# Info: Scrapes Federal Members list from the Australian Parliment House web
#       site, and spits out the list in a friendly tab seperated format.
# Author: Andrew Harvey (http://andrewharvey4.wordpress.com/)
# Date: 21 Dec 2009 
#
# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

# Usage: ./

use warnings;
use strict;

use LWP::Simple;
my $content = get('http://www.aph.gov.au/house/members/mi-alpha.asp');

my @html_lines = split /\n/, $content;

@html_lines = grep(/href=\"?member\.asp\?id=/, @html_lines);

#my $URL_PREFIX = "http://www.aph.gov.au/house/members/";
my $URL_PREFIX = "";

#parse.
#result is tab seperated,
#url_link   member_name   electorate
foreach (@html_lines) {
    $_ =~ s/.*<a href=//; #remove junk at start of line
    $_ =~ s/<\/a.*//; #remove junk at end of line
    
    $_ =~ s/>/\t/; #tab seperate
    $_ =~ s/, Member for */\t/; #tab seperate

    $_ =~ s/, */, /; #clean up any messy SURNAME,     FIRSTNAME

    print "${URL_PREFIX}$_\n";
}
