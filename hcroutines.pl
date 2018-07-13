#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

#
# Using the Handicap formula, determine how many scores to use.
#
sub nscores {
        my ($x) = @_;

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
        return(10);
}

#
# Rounds to the nearest hundredth position.
#
sub round_hundredth {
	my ($r) = @_;

	$r *= 100;
	$r = int($r + 0.5);
	$r /= 100;
	return ($r);
}

#
# Rounds to the nearest tenth position.
#
sub round_tenth {
	my ($r) = @_;

	$r *= 10;
	$r = int($r + 0.5);
	$r /= 10;
	return ($r);
}

#
# routine to check scores for errors.
#
sub check_scores {

        my ($o, $t, $th, $f, $fv, $s, $sv, $e, $n) = @_;

        #
        # If the first few scores are not defined, then its probaly a score
        # that wasn't post with hole by hole method. Just skip it.
        #
        if (!defined($o) && !defined($t) && !defined($th) && !defined($f)) {
                return;
        }

        #
        # Make sure no hole has a zero for a score.
        #
        if ($o == 0 || $t == 0 || $th == 0 || $f == 0 || $fv == 0 ||
                    $s == 0 ||  $sv == 0 || $e == 0 || $n == 0) {
                        print "$date Scoring error. $name: $o  $t  $th  $f  $fv  $s  $sv  $e  $n\n";
        }
}

1;
