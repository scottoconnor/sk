#! /usr/bin/perl
#
# Copyright (c) 2018, 2026 Scott O'Connor
#

use strict;
use warnings;
use Getopt::Long;

my $year = (1900 + (localtime)[5]);
my $out = 0;
my @line;
my @nline;
my $log;

GetOptions (
    "y=s" => \$year,
    "o" =>  \$out)
or die("Error in command line arguments\n");

if ($out) {
    unlink "/tmp/stats-$year.txt", if -e "/tmp/stats-$year.txt";
    open ($log, ">", "/tmp/stats-$year.txt");
    select $log;
} else {
    select STDOUT;
}

@line = qx{./skperf.pl -t -sy 2003 -ey $year | grep -A 1 "Birdie Table"};
my $num = @line;
my $x = 0;

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

@line = qx{./skperf.pl -t -sy 2003 -ey $year | grep -A 1 "Eagle Table"};
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
@line = qx{./skperf.pl -m -y $year};
print @line;

print "\n\n";

#
# The array @line can be used in the next two stats,
# so there is not need to run ./skperf twice.
#
print "$year player net average scoring vs. par\n";
print "---------------------------------------\n";
@line = qx{./skperf.pl -vhc -y $year};
@nline = grep(/Ave = /, @line);
print @nline;

print "\n\n";

print "$year Player week by week stats\n";
print "------------------------------\n";
@line = qx{./skperf.pl -vhc -y $year};
@nline = grep(/net /, @line);
print @nline;

print "\n\n";

print "$year Course Stats\n";
print "-----------------\n";
@line = qx{./skperf.pl -c -y $year};
print @line;

print "\n\n";

print "$year Hardest to Easiest Holes\n";
print "-----------------------------\n";
@line = qx{./skperf.pl -H -y $year};
print @line;

print "\n\n";

print "$year Hardest to Easiest Holes Per Nine\n";
print "--------------------------------------\n";
@line = qx{./skperf.pl -H -y $year};
@nline = grep(/South Front/, @line);
print @nline, "\n\n";
@nline = grep(/South Back/, @line);
print @nline, "\n\n";
@nline = grep(/North Front/, @line);
print @nline, "\n\n";
@nline = grep(/North Back/, @line);
print @nline;


my $low_net = 25;
my $high_net = 60;

print "$year Lowest to Highest net scores\n";
print "---------------------------------\n";
@line = qx{./skperf.pl -vhc -y $year};
for ($low_net = 25; $low_net <= $high_net; $low_net++) {
    my $num = grep(/net $low_net/, @line);
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
for (my $y = 2003; $y <= $year; $y++) {
    print "$y\n";
    @line = qx{./skperf.pl -vhc -y $y grep "net = "};
    my $cnt = 0;
    while ((my $temp_line = shift @line) && ($cnt < 5)) {
        chomp($temp_line);
        (my $num_rounds) = $temp_line =~ /total rounds (\d+)/;
        if (!defined($num_rounds)) {
            next;
        }
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
@line = qx{./skperf.pl -g -y $year};
print @line;

print "\n\n";

print "$year Others break down\n";
print "----------------------\n";
@line = qx{./skperf.pl -o -y $year};
print @line;

print "\n\n";

print "$year detailed player stats\n";
print "--------------------------\n";
@line = qx{./skperf.pl -p -y $year};
print @line;

print "\n\n";


print "2003-2024 detailed player stats\n";
print "-------------------------------\n";
@line = qx{./skperf.pl -p -sy 2003 -ey 2024};
print @line;

print "\n\n";

print "2025 detailed player stats\n";
print "-------------------------------\n";
@line = qx{./skperf.pl -p -y 2025};
print @line;

print "\n\n";

print "All time stats (1997-$year)\n";
print "--------------------------\n";
@line = qx{./skperf.pl -at -ey $year};
print @line;

if ($out) {
    close($log);
}
