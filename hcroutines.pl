#! /usr/bin/perl
#
# Copyright (c) 2018, 2023 Scott O'Connor
#

use POSIX;
use GDBM_File;
require './tnfb_years.pl';

#
# Determine how many scores to use.
#
# Starting in 2020, the World Handicap System was implemented.  The number
# of scores used is different than the previous USGA handicap formula.
#
sub nscores {
    my ($x, $usga) = @_;

    if ($usga) {
        if ($x < 5) { return 0; }

        if ($x >= 5 && $x <= 6) { return 1; }
        if ($x >= 7 && $x <= 8) { return 2; }
        if ($x >= 9 && $x <= 10) { return 3; }
        if ($x >= 11 && $x <= 12) { return 4; }
        if ($x >= 13 && $x <= 14) { return 5; }
        if ($x >= 15 && $x <= 16) { return 6; }
        if ($x == 17) { return 7; }
        if ($x == 18) { return 8; }
        if ($x == 19) { return 9; }
        if ($x >= 20) { return 10; }
    } else {
        if ($x < 3) { return 0; }

        if ($x >= 3 && $x <= 5) { return 1; }
        if ($x == 6) { return 2; }
        if ($x >= 7 && $x <= 8) { return 2; }
        if ($x >= 9 && $x <= 11) { return 3; }
        if ($x >= 12 && $x <= 14) { return 4; }
        if ($x >= 15 && $x <= 16) { return 5; }
        if ($x >= 17 && $x <= 18) { return 6; }
        if ($x == 19) { return 7; }
        if ($x >= 20) { return 8; }
    }
}

#
# This routine will round a number (positive or negative) to the
# nearest "factor" supplied.  1.54 rounded to the nearest 10th, the
# factor sent in should be "10".
#
sub round {
    my ($a, $factor) = @_;
    my ($e, $r);

    $r = ($a * $factor);
    if ($r =~ /\d*\056(\d{1})/) {
        $e = $1;
    }

    if (!defined($e)) {
        return ($a);
    }

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
    my ($fn, $year) = @_;
    my (@scores, $y, $hi, $use, @n, $num_scores);

    ($first, $last) = split(/:/, $tnfb_db{'Player'});
    $team = $tnfb_db{'Team'};
    $active = $tnfb_db{'Active'};

    #if ($active == 0) {
        #return;
    #}

    $num_scores = 0;
    foreach $y (reverse (1997..$year)) {
        foreach $w (reverse (1..15)) {
            if (exists($tnfb_db{$dates{$y}{$w}})) {
                push (@scores, $tnfb_db{$dates{$y}{$w}});
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
                    my $newdate = "$y-$m-$d";
                    if (exists($tnfb_db{$newdate})) {
                        push (@scores, $tnfb_db{$newdate});
                        $num_scores++;
                    }
                    last, if ($num_scores == 20);
                }
                last, if ($num_scores == 20);
            }
            last, if ($num_scores == 20);
        }
    }

    $num = @scores;

    if ($num > 20) {
        die "$tnfb_db{'Player'}: Number of score is more than 20.\n";
    }

    #
    # Make 10 the number of score for a League Handicap. Anything under
    # this, refer to the players World Handicap index.
    #
    return (-100), if ($num < 10);

    #
    # If the player does not have the required number of scores,
    # a handicap can not be generted for them.
    #
    if (($use = &nscores($num, 0)) == 0) {
        return (-100);
    }

    $y = 0;
    foreach my $s (@scores) {

        ($course, $course_rating, $slope, $date, $aa, $bb, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
            split(/:/, $s);

        if ($post == 100) {
            print "Bogus posted score of -> $post, need to fix.\n";
        }

        $n[$y] = ((113 / $slope) * ($post - $course_rating));

        if ($shot > 75) {
            $n[$y] /= 2;
        }

        #
        # Round to the nearest tenth.
        #
        $n[$y] = round($n[$y], 10);
        printf("date=%s: post=%d: differential: %.1f\n", $date, $post, $n[$y]), if $debug;

        $y++;
    }

    @n = sort {$a <=> $b} @n;

    $hi = 0;

    for ($y = 0; $y < $use; $y++) {
        printf("%d: %.1f\n", $y, $n[$y]), if $debug;
        $hi += $n[$y];
    }

    $hi /= $use;
    $hi = round($hi, 10);

    return ($hi);
}
1;
