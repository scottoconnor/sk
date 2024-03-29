#! /usr/bin/perl
#
# Copyright (c) 2018, 2024 Scott O'Connor
#

require './tnfb_years.pl';

use POSIX;
use GDBM_File;

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
gen_hi {
    my ($year);
    my (@scores, $y, $hi, $use, @n, $num_scores, $d);

    $year = (1900 + (localtime)[5]);

    $num_scores = 0;
    foreach $y (reverse (1997..$year)) {
        foreach $w (reverse (1..15)) {
            $d = $dates{$y}{$w};
            if (exists($tnfb_db{$d})) {
                push (@scores, $tnfb_db{$d});
                $num_scores++;
            }
            last, if ($num_scores == 20);
        }
        last, if ($num_scores == 20);
    }

    if ($num_scores < 20) {
        undef @scores;
        $num_scores = 0;
        foreach $y (reverse (1997..$year)) {
            foreach $m (reverse (1..12)) {
                foreach $d (reverse (1..31)) {
                    my $d = "$y-$m-$d";
                    if (exists($tnfb_db{$d})) {
                        push (@scores, $tnfb_db{$d});
                        $num_scores++;
                    }
                    last, if ($num_scores == 20);
                }
                last, if ($num_scores == 20);
            }
            last, if ($num_scores == 20);
        }
    }

    #
    # If the player does not have the required number of scores,
    # a handicap can not be generted for them.
    #
    if (($use = &nscores($num_scores)) == 0) {
        return (-100);
    }

    $y = 0;
    foreach my $s (@scores) {

        @sr = split(/:/, $s);

        $n[$y] = ((113 / $sr[2]) * ($sr[7] - $sr[1]));

        #
        # Round to the nearest tenth.
        #
        $n[$y] = round($n[$y], 10);

        $y++;
    }

    @n = sort {$a <=> $b} @n;

    $hi = 0;

    for ($y = 0; $y < $use; $y++) {
        $hi += $n[$y];
    }

    $hi /= $use;
    $hi = round($hi, 10);

    return ($hi);
}
1;
