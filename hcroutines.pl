#! /usr/bin/perl
#
# Copyright (c) 2018, 2024 Scott O'Connor
#

require './tnfb_years.pl';

use strict;
use POSIX;
use GDBM_File;

our (%dates);

#
# Determine how many scores to use.
#
# Due to the discrepancies of WHS and League handicap indexes, do
# not calculate a TNFB league handicap until 10 scores are in the record.
#
sub
nscores {
    my ($x) = @_;

    if ($x < 10) { return 0; }

    #if ($x < 3) { return 0; }
    #if ($x >= 3 && $x <= 5) { return 1; }
    #if ($x == 6) { return 2; }
    #if ($x >= 7 && $x <= 8) { return 2; }
    #if ($x >= 9 && $x <= 11) { return 3; }
    #
    # 10 or more scores. modified from line above.
    #
    if ($x > 9 && $x <= 11) { return 3; }

    if ($x >= 12 && $x <= 14) { return 4; }
    if ($x >= 15 && $x <= 16) { return 5; }
    if ($x >= 17 && $x <= 18) { return 6; }
    if ($x == 19) { return 7; }
    if ($x >= 20) { return 8; }
}

#
# This routine will round a number (positive or negative) to the
# nearest "factor" supplied.  1.54 rounded to the nearest 10th, the
# factor sent in should be "10".
#
sub round {
    my ($a, $factor) = @_;
    my ($e, $r);

    undef ($e);

    $r = ($a * $factor);

    #
    # After we multiply it by the factor, truncate everything after
    # the first digit after the decimal point. Not needed.
    #
    ($r) = $r =~ /(\055*\d*\056\d{1})/;

    #
    # See if there is a digit after the decmial point.
    #
    ($e) = $r =~ /\d*\056(\d{1})/;

    #
    # No digit after the decimal point, return the number passed in.
    #
    return ($a), if (!defined($e));

    if ($r < 0) {
        if ($e <= 5) {
            $r = ceil($r);
        } else {
            $r = floor($r);
        }
    } else {
        if ($e >= 5) {
            $r = ceil($r);
        } else {
            $r = floor($r);
        }
    }
    $r /= $factor;
    return ($r);
}

sub
get_course_data {
    my ($year, $course) = @_;

    if ($year >= 1995 and $year <= 2024) {
        #
        # Par and handicap hole for each hole.
        #
        if ($course eq "SF") {
            return("South Front:34.8:127:36:4:4:3:4:5:5:3:4:4:7:1:9:5:3:4:2:8:6");
        }
        if ($course eq "SB") {
            return("South Back:34.7:121:36:5:3:4:4:5:3:4:3:5:2:9:5:7:8:6:1:4:3");
        }
    } elsif ($year >= 2025) {
        #
        # Par and handicap hole for each hole.
        #
        if ($course eq "SF") {
            return("South Front:35.0:119:36:4:4:3:4:4:4:5:5:3:7:1:9:5:6:8:3:4:2");
        }
        if ($course eq "SB") {
            return("South Back:34.2:129:35:4:3:4:4:5:3:4:3:5:7:1:9:5:6:8:3:4:2");
        }
    }
    if ($course eq "NF") {
        return("North Front:35.6:124:36:5:4:4:4:5:3:4:3:4:3:6:7:2:4:5:8:9:1");
    }
    if ($course eq "NB") {
        return("North Back:35.1:130:36:4:4:5:3:4:4:3:4:5:2:3:9:8:7:4:6:5:1");
    }
}
1;
