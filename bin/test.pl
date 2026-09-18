#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use warnings;
use POSIX;
use Getopt::Long;

my $year = (1900 + (localtime)[5]);

GetOptions (
    "y=s" => \$year)
or die("Error in command line arguments\n");

my $val;

foreach $year ($year..$year) {
    foreach my $week (1..15) {
        $val = 0;
        my $ret = qx{./skperf.pl -s -y $year -w $week | grep "League Stroke Average"};
        ($val) = $ret =~ /League Stroke Average = (\d+\.\d+)/;
    
        printf("%d:%d, Stroke Average %.2f\n", $year, $week, $val);
    }
}
