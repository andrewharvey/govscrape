#!/usr/bin/perl -w

# Info: Scrapes foodauthority.nsw.gov.au's Register of penalty notices and 
#       returns results in an XML format.
# Author: Andrew Harvey (http://andrewharvey4.wordpress.com/)
# Date: 26 Jun 2010
#
# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

# = README =
# I've tried to add in many checks so that if the food authority people change
# the structure of the HTML files you won't end up with incorrect output. As a
# result you may not be able to successfully run this script in the future.

# You probably should take a look at the Food Authority's web site before you
# use scraped data in a serious way, they have more details about what all the 
# data means.

# I should probably use the full LWP::UserAgent module rather than LWP::Simple.
# As a result scraping is slow as the connection is closed after each GET.

# There are too many options for what format to output the results as. XML 
# should be flexible enough to make it easier to convert to another format.
# I'm particually interested in geocoding the address of each notice and
# converting it to GeoRSS. I see much of the same processes being done for 
# planningalerts.org.au, ie. you have a register of geolocated entries being 
# updated and you want to server two main use cases, being able to provide a map
# of the entries with associated metadata available, and also provide an RSS 
# feed so that people can be notified for new entries added in location's of 
# interest to them.

use strict;

use LWP::Simple;
use HTML::TreeBuilder;

use XML::Writer;

sub get_notice($$);


(print("Usage: $0 output.xml\n") && exit) unless defined $ARGV[0];

#global variables
my $xmlout = new IO::File(">$ARGV[0]");
my $xmlwriter = new XML::Writer(OUTPUT => $xmlout);

my $URL_BASE = 'http://www.foodauthority.nsw.gov.au';
my $START_PAGE = $URL_BASE.'/penalty-notices/default.aspx';
my $START_ARGUMENTS = '?template=results';

#get index html page which lists all the notices
my $html = get($START_PAGE.$START_ARGUMENTS);
die "Problem getting HTTP resource." unless defined $html;

#find when the list was last updated
my $last_updated;
if ($html =~ /Last updated on (\d+ \w+ \d+)/) {
    $last_updated = $1;
}else {
    die("Couldn't determine when the list was last update");
}

#and what time we are scraping
my $time = localtime;

#start the XML file
$xmlwriter->startTag("foodauth_penalty_notices", "scrapedate" => "$time",
                     "lastupdated" => "$last_updated");

#if the process gets killed, end the tag early (shouldn't XML::Writer clean this?)
$SIG{INT} = sub { $xmlwriter->endTag("foodauth_penalty_notices"); };

#find out how many notices they claim to display (used for the progress bar)
my $num_notices = undef;
if ($html =~ /<strong>(\d+)<\/strong> penalty notices displayed/) {
    $num_notices = $1;
    print "$num_notices notices\n";
}

#parse the HTML of the index page
my $element;
my $tree = HTML::TreeBuilder->new;
$tree->parse($html); $tree->eof;
$tree->elementify();

#find the table that lists all the data
my @table = $tree->look_down('_tag', 'table',
                                     'class', 'table-data-pen sortable');

my @rows = $table[0]->look_down('_tag','tr');

shift @rows; #we don't need the header of the table...
my $index = 1;
foreach my $row (@rows) {
    if (defined $row) {
        my ($tradename, $suburb, $council, $noticeno, $date, $party, $notes)
             = $row->look_down('_tag', 'td');
             
        print (int((100 * $index) / $num_notices)."\% ") unless !defined $num_notices;
             
        print $tradename->as_text().", ";
        print $suburb->as_text().", ";
        print $council->as_text().", ";
        print $noticeno->as_text().", ";
        
        my $notice_link = $noticeno->look_down('_tag', 'a')->attr('href');
        $notice_link =~ /itemId=(\d*)/;
        if ($1 ne $noticeno->as_text()) {
            die "Notice link ($1) does not match text number (".$noticeno->as_text().")\n";
        }
        
        print $date->as_text().", ";
        print $party->as_text().", ";
        print $notes->as_text();

		$xmlwriter->startTag('notice', 'notice_number' => $noticeno->as_text());
        get_notice($START_PAGE.$notice_link, $noticeno->as_text());
        $xmlwriter->endTag('notice');
        
        print "\n";
        $index++;
    }
}

#finish the XML file and exit
$xmlwriter->endTag("foodauth_penalty_notices");
print "Successfully Completed.\n";
exit;

#get and scrape a single notice page
sub get_notice($$) {
	my ($link, $notice_num) = @_;
	
	my $notice_html = get($link);
    die "Problem getting HTTP resource." unless defined $notice_html;
	
	my $element;
	my $tree = HTML::TreeBuilder->new;
	$tree->parse($notice_html); $tree->eof;
	$tree->elementify();
	
	#find the table that lists all the data
    my @table = $tree->look_down('_tag', 'table',
                                         'class', 'table-data-pros');

    my @rows = $table[0]->look_down('_tag','tr');
	my $i = 0;
    my ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Penalty notice number") {die "problem1"};
    if ($c1->as_text() ne $notice_num) {die "problem2"};
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Trade name of party served(or name of place of business)") {die "problem3"};
    my $trading_name = $c1->as_text();
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Address(where offence occurred)") {die "problem4".$c0->as_text()};
    my $address = $c1->as_text();
    $address =~ s/\s$//; #remove trailing whitespace
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Council(where offence occurred)") {die "problem5"};
    my $council = $c1->as_text();
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Date of alleged offence(yyyy-mm-dd)") {die "problem6"};
    my $date = $c1->as_text();
    if ($date !~ '\d\d\d\d-\d\d-\d\d') {
    	$date = '0000-00-00';
    }
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Offence code") {die "problem7"};
    my $offence_code = $c1->as_text();
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Nature & circumstances of alleged offence") {die "problem8"};
    my $nature = $c1->as_text();
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Amount of penalty ") {die "problem9"};
    my $penalty = $c1->as_text();
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Name of party served(with penalty notice)") {die "problem10"};
    my $party_served = $c1->as_text();
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Date penalty notice served(yyyy-mm-dd)") {die "problem11"};
    my $date_served = $c1->as_text();
    if ($date_served !~ '\d\d\d\d-\d\d-\d\d') {
    	$date_served = '0000-00-00';
    }
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Issued by") {die "problem12"};
    my $issued_by = $c1->as_text();
    
    ($c0, $c1) = $rows[$i++]->look_down('_tag', 'td');
    if ($c0->as_text() ne "Notes") {die "problem13"};
    my $notes = $c1->as_text();
        
    #write it out to the XML writer
	$xmlwriter->dataElement('url', $link);
	$xmlwriter->dataElement('trading_name', $trading_name);
	$xmlwriter->dataElement('address', $address);
	$xmlwriter->dataElement('council', $council);
	$xmlwriter->dataElement('date', $date);
	$xmlwriter->dataElement('offence_code', $offence_code);
	$xmlwriter->dataElement('nature', $nature);
	$xmlwriter->dataElement('penalty', $penalty);
	$xmlwriter->dataElement('party_served', $party_served);
	$xmlwriter->dataElement('date_served', $date_served);
	$xmlwriter->dataElement('issued_by', $issued_by);
	$xmlwriter->dataElement('notes', $notes);
}



