#! /usr/bin/perl
#
# Copyright (c) 2018, 2026 Scott O'Connor
#

use strict;
use POSIX;

use GDBM_File;
use Time::Piece;
use Time::Seconds;
use warnings;

my $end_year = localtime->year;
my $sy;
my $t;
my ($year, $month, $day, $date);
my %tnfb_db;
my %d;
our %dates;
my $league = "./golfers";
my $dh;
my $golfers;
my %golfers_gdbm;

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
    $r =~ /(\055*\d*\056\d{1})/;

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

    if ($year == 2025) {
        #
        # Par and handicap hole for each hole.
        #
        if ($course eq "SF") {
            return("South Front:35.0:119:36:4:4:3:4:4:4:5:5:3:7:1:9:5:6:8:3:4:2");
        }
        if ($course eq "SB") {
            return("South Back:34.2:129:35:4:3:4:4:5:3:4:3:5:8:9:5:7:2:6:1:4:3");
        }
    } elsif ($year == 2026) {
        if ($course eq "SF") {
            return("South Front:35.0:119:36:4:4:3:4:4:4:5:5:3:7:1:9:4:2:8:3:5:6");
        }
        if ($course eq "SB") {
            return("South Back:34.2:129:35:4:3:4:4:5:3:4:3:5:8:9:5:7:2:6:1:4:3");
        }
        if ($course eq "NF") {
            return("North Front:34.1:121:35:4:4:3:4:4:5:3:4:4:2:3:9:6:1:4:5:8:7");
        }
    } elsif ($year >= 2027) {
        if ($course eq "SF") {
            return("South Front:35.0:119:36:4:4:3:4:4:4:5:5:3:3:1:9:6:2:7:4:5:8");
        }
        if ($course eq "SB") {
            return("South Back:34.2:129:35:4:3:4:4:5:3:4:3:5:7:9:5:3:4:8:1:6:2");
        }
        if ($course eq "NF") {
            return("North Front:34.1:121:35:4:4:3:4:4:5:3:4:4:2:3:7:4:1:9:8:6:5");
        }
    }

    if ($course eq "SF") {
        return("South Front:34.8:127:36:4:4:3:4:5:5:3:4:4:7:1:9:5:3:4:2:8:6");
    }
    if ($course eq "SB") {
        return("South Back:34.7:121:36:5:3:4:4:5:3:4:3:5:2:9:5:7:8:6:1:4:3");
    }
    if ($course eq "NF") {
        return("North Front:35.6:124:36:5:4:4:4:5:3:4:3:4:3:6:7:2:4:5:8:9:1");
    }
    if ($course eq "NB") {
        return("North Back:35.1:130:36:4:4:5:3:4:4:3:4:5:2:3:9:8:7:4:6:5:1");
    }
}

sub
get_years_weeks_dates {

    opendir($dh, "$league") || die "Can't open \"$league\" directory.";

    while (readdir $dh) {
        if ($_ =~ /(^1\d{3}\056gdbm)/) {
            tie %tnfb_db, 'GDBM_File', "$league/$_", GDBM_READER, 0644
                or die "$GDBM_File::gdbm_errno";
            $golfers_gdbm{$tnfb_db{'Player'}} = "$league/$_";
            untie %tnfb_db;
        }
    }

    foreach my $pn (keys %golfers_gdbm) {

        my $file = $golfers_gdbm{$pn};
        my $scores = 0;

        tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0644
            or die "$GDBM_File::gdbm_errno";

        my $pn =  $tnfb_db{'Player'};

        $sy = 1997;
        $t = Time::Piece->strptime("$sy-04-01", "%Y-%m-%d");

        while ($sy <= $end_year) {

            ($year, $month, $day) = $t->ymd =~ /(\d{4})-\060*(\d{1,2})-\060*(\d{1,2})/;
            $date = "$year-$month-$day";

            # If the score exists, check if the day is Tuesday
            if ((exists($tnfb_db{$date})) && ($t->fullday eq 'Tuesday')) {
                $d{$date} = $date;
            }

            # Move to next day
            if (exists($d{$date})) {
                $t += ONE_WEEK;
            } else {
                $t += ONE_DAY;
            }
            if ($t->mon > 8) {
                if ($sy > 2002) {
                    do {
                        $sy++;
                    } while ((!exists($tnfb_db{"Team_$sy"})) && ($sy <= $end_year));
                } else {
                    $sy++;
                }
                $t = Time::Piece->strptime("$sy-04-01", "%Y-%m-%d");
            }
        }
        untie %tnfb_db;
    }

    my $week = 1;
    $sy = 1997;
    $t = Time::Piece->strptime("$sy-04-01", "%Y-%m-%d");

    while ($sy <= $end_year) {
        ($year, $month, $day) = $t->ymd =~ /(\d{4})-\060*(\d{1,2})-\060*(\d{1,2})/;
        $date = "$year-$month-$day";
        if (exists($d{$date})) {
            $dates{$year}{$week} = $d{$date};
            $dates{$year}{weeks} = $week;
            print "$year: $week: $date: $d{$date}\n", if (0);
            $week++;
        }

        if (exists($d{$date})) {
            $t += ONE_WEEK;
        } else {
            $t += ONE_DAY;
        }

        if ($t->mon > 8) {
            $sy++;
            $t = Time::Piece->strptime("$sy-04-01", "%Y-%m-%d");
            $week = 1;
        }
    }
}
1;
