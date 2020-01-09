#! /usr/bin/perl
#
# Copyright (c) 2018, 2019, Scott O'Connor
#

use Getopt::Long;

$year = 2019;

GetOptions (
	"y=s" => \$year,
	"o" =>  \$out)
or die("Error in command line arguments\n");

$cur_year = $year;
$start_year = 2003;

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

for (my $week = 1; $week < 16; $week++) {
    $s = `./skperf.pl -s -y $year -w $week | grep "Total holes played"`;
    ($s) = $s =~ /Total holes played: (\d+)/;
    if ($s > 0) {
	$num_weeks++;
    }
}

if ($num_weeks == 15) {
    open ($log, ">", "/tmp/$start_year-$cur_year.html");
} else {
    open ($log, ">", "/tmp/$start_year-$cur_year-week-$num_weeks.html");
}
open ($log2, ">", "/tmp/$start_year-$cur_year-only-week-$num_weeks.html");

#
# Now generate the weekly stats for these weeks from start year to cur year
#
while ($start_year <= $year) {
    select $log;
    @line = `./skperf.pl -s -t -h -y $year -sw 1 -ew $num_weeks`;
    print @line;
    print "<br><br>\n";
    select $log2;
    @line = `./skperf.pl -s -t -h -y $year -w $num_weeks`;
    print @line;
    print "<br><br>";
    $year--;
}
close($log);
close($log2);

#
# Get the stats and table for the current year, then tack the
# weekly stats below the overall stats.
#

open ($log, ">", "/tmp/$cur_year.html");
select $log;

@line = `./skperf.pl -s -t -h -y $cur_year`;
print @line;
print "<br><br>";

$week = $num_weeks;
while ($week > 0) {
    @line = `./skperf.pl -h -s -t -y $cur_year -w $week`;
    print @line;
    @line = `./skperf.pl -h -g -y $cur_year -w $week`;	
    print @line;
    print "<br><br>";
    $week--;
}

@line = `./stats.pl -y $cur_year -w -h`;
print @line;
@line = `./stats.pl -y $cur_year -c -h`;
print @line;

close ($log);
