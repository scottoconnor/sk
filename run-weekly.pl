#! /usr/bin/perl
#
# Copyright (c) 2018, 2026, Scott O'Connor
#

use strict;
use Getopt::Long;
use POSIX;

my $year = (1900 + (localtime)[5]);

GetOptions (
        "y=i" => \$year)
or die("Error in command line arguments\n");

my $cur_year = $year;
my $start_year = 2003;
my $dh;
my $fh;
my $week;
my $num_weeks;
my $s;
my $th;
my @line;
my @html_list;

#
# First, remove old html file from /tmp
#
opendir($dh, "/tmp") || die "Can't open /tmp directory.";

while (readdir $dh) {
    if ($_ =~ /[0-9a-zA-Z\055]\056html/) {
        push @html_list, "/tmp/$_";
    }
}
closedir ($dh);

unlink @html_list;

#
# First, find out how many weeks of golf have been played in the year specified.
#
$num_weeks = 0;

$s = qx(./skperf.pl -s -y $year | grep \"Total holes played\");
($th) = $s =~ /Total holes played: (\d+)/;
$num_weeks = ceil(($th/288));
print "Number of weeks: $num_weeks\n";

#
# Get the stats and table for the current year, then tack the
# weekly stats below the overall stats.
#

open ($fh, ">", "/tmp/$cur_year.html");
select $fh;

@line = qx{./skperf.pl -s -t -h -y $cur_year};
print @line;
print "<br>";

$week = $num_weeks;
while ($week > 0) {
    @line = qx{./skperf.pl -h -s -g -t -y $cur_year -w $week};
    print @line;
    print "<br>";
    $week--;
}

@line = qx(./stats.pl -w -c -h -y $cur_year);
print @line;

close ($fh);
