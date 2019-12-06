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

print "Year is $year\n";

if ($out) {
    unlink "/tmp/stats-$year.txt", if -e "/tmp/stats-$year.txt";
    open (my $log, ">", "/tmp/stats-$year.txt");
    select $log;
} else {
    select STDOUT;
}

@line = `./skperf.pl -t -sy 2003 -ey $year | grep -A 1 "Birdie Table"`;
$num = @line;
$x = 0;

print "Yearly Birdie winners\n";
print "---------------------\n";
while ($x < $num) {
    chop ($line[$x]);
    print "$line[$x] ";
    $x++;
    chop ($line[$x]);
    print "$line[$x]\n";
    $x++; $x++;
}

print "\n\n";

@line = `./skperf.pl -t -sy 2003 -ey $year | grep -A 1 "Eagle Table"`;
$num = @line;
$x = 0;

print "Yearly Eagle winners\n";
print "--------------------\n";
while ($x < $num) {
    chop ($line[$x]);
    print "$line[$x] ";
    $x++;
    chop ($line[$x]);
    print "$line[$x]\n";
    $x++; $x++;
}

print "\n\n";

print "$year Most Improved (best to not so best)\n";
print "----------------------------------------\n";
@line = `./skperf.pl -m -y $year`;
print @line;

print "\n\n";

#
# The array @line can be used in the next two stats,
# so there is not need to run ./skperf twice.
#
print "$year player net average scoring vs. par\n";
print "---------------------------------------\n";
@line = `./skperf.pl -vhc -y $year`;
@nline = grep(/TNFB/, @line);
@nline = grep(/Ave = /, @nline);
print @nline;

print "\n\n";

print "$year Player week by week stats\n";
print "------------------------------\n";
@nline = grep(!/Sub/, @line);
@nline = grep(!/TNFB/, @nline);
print @nline;


print "$year Course Stats\n";
print "-----------------\n";
@line = `./skperf.pl -c -y $year`;
print @line;

print "\n\n";

print "$year Hardest to Easiest Holes\n";
print "-----------------------------\n";
@line = `./skperf.pl -ha -y $year`;
print @line;

print "\n\n";

print "$year Hardest to Easiest Holes Per Nine\n";
print "--------------------------------------\n";
@line = `./skperf.pl -ha -y $year`;
@nline = grep(/South Front/, @line);
print @nline, "\n\n";
@nline = grep(/South Back/, @line);
print @nline, "\n\n";
@nline = grep(/North Front/, @line);
print @nline, "\n\n";
@nline = grep(/North Back/, @line);
print @nline, "\n\n";


$low_net = 25;
$high_net = 60;

print "$year Lowest to Highest net scores\n";
print "---------------------------------\n";
@line = `./skperf.pl -vhc -y $year`;
for ($low_net = 25; $low_net <= $high_net; $low_net++) {
    $num = grep(/net $low_net/, @line);
    if ($num > 0) {
	print "Number of net $low_net scores: $num\n";
	@nline = grep(/net $low_net/, @line);
	print @nline, "\n";
    }
}

print "\n\n";

print "Top 5 by year: Lowest to Highest average net scores\n";
print "(need at least 10 rounds to qualify)\n";
print "---------------------------------------------------\n";
for ($y = 2003; $y <= $year; $y++) {
    print "$y\n";
    @line = `./skperf.pl -vhc -y $y | grep TNFB | grep "Ave = "`;
    $cnt = 0;
    while (($temp_line = shift @line) && ($cnt < 5)) {
	chomp($temp_line);
	($num_rounds) = $temp_line =~ /total rounds (\d+)/;
	if ($num_rounds >= 10) {
    	    print "$temp_line\n";
	    $cnt++;
	}
    }
    print "\n";
}

print "\n\n";

print "$year 30's Club\n";
print "--------------\n";
@line = `./skperf.pl -g -y $year`;
print @line;

print "\n\n";

print "$year Others break down\n";
print "----------------------\n";
@line = `./skperf.pl -o -y $year`;
print @line;

print "\n\n";

print "$year detailed player stats\n";
print "--------------------------\n";
@line = `./skperf.pl -p -y $year`;
print @line;

print "\n\n";

print "2003-$year detailed player stats\n";
print "-------------------------------\n";
@line = `./skperf.pl -p -sy 2003`;
print @line;

print "\n\n";

print "2003-$year detailed player stats\n";
print "-------------------------------\n";
@line = `./skperf.pl -p -sy 2003 -ey $year`;
print @line;

print "\n\n";

print "All time stats (1997-$year)\n";
print "--------------------------\n";
@line = `./skperf.pl -at -ey $year`;
print @line;

if ($out) {
    close($log);
}
