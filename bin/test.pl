#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use warnings;
use POSIX;

my ($year, $week, $ret, $val);

for ($year = 2026; $year < 2027; $year++) {
    for ($week = 1; $week < 16; $week++) {
        $val = 0;
        $ret = qx{./skperf.pl -s -y $year -w $week | grep "League Stroke Average"};
        ($val) = $ret =~ /League Stroke Average = (\d+\.\d+)/;
    
        printf("%d:%d, Stroke Average %.2f\n", $year, $week, $val);
    }
}
