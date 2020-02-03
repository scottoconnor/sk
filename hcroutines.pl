#! /usr/bin/perl
#
# Copyright (c) 2018, 2020 Scott O'Connor
#

use POSIX;

#
# Determine how many scores to use.
#
# Starting in 2020, the World Handicap System was implemented.  The number
# of scores used is different than the previous USGA handicap formula.
# Need to keep the USGA method for when a players trend is calculated.
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

sub gen_hc_trend {
    my ($fn, $allowance) = @_;
    my (@scores, $x, $y, $hi, $use, @n, $num_scores, $usga);

    undef @n;

    open(FD, $fn);
    @scores = <FD>;
    close(FD);

    chomp($scores[0]);
    ($first, $last, $team, $active) = split(/:/, $scores[0]);
    $pn = $first . " " . $last;

    if ($team ne "Sub") {
	$team = "TNFB";
    }

    shift @scores;

    $num = @scores;

    #
    # Set default handicap to USGA formula.  Logic will change it below if needed.
    #
    $usga = 1;

    if (($use = nscores($num, $usga)) == 0) {
	print "$pn: Only $num scores, not enough to generate a trend.\n", if $debug;
	return;
    }

    $first_score = 0; $last_score = 5;
    $num_scores = ($last_score - $first_score);

    while ($last_score <= $num) {
	$y = 0; undef @n;
	while ($first_score < $last_score) {

	    $s = $scores[$first_score];
	    chomp($s);
	    ($course, $course_rating, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
		split(/:/, $s);

	    #
	    # If a single score in the mix is from 2020 or later, we need to
	    # make sure the WHS formula is used.  If all scores are previous
	    # to the year 2020, use the USGA formula.
	    #
	    ($year, $month, $day) = split(/-/, $date);
	    $usga = ($year < 2020) ? 1 : 0;

	    $n[$y] = ((113 / $slope) * ($post - $course_rating));

	    if ($shot > 75) {
		$n[$y] /= 2;
	    }
	    $n[$y] = round($n[$y], 10);

	    printf("date=%s: post=%d: differential: %.1f\n", $date, $post, $n[$y]), if $debug;

		$first_score++;
		$y++;
	}

	if ($last_score < $num) {
	    $s = $scores[$last_score];
	    chomp($s);
	    ($course, $course_rating, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
		split(/:/, $s);
	    ($year, $month, $day) = split(/-/, $date);

	    #
	    # If this is the last score that is posted for 2019, force the next
	    # score to use the World Handicap System.  This will generate the
	    # first handicap for the 2020 season.  We know that this is the last
	    # score for the 2019 season if the next score posted is from 2020.
	    #
	    if ($year == 2020 && ($usga == 1)) {
		$usga = 0;
	    }
	} elsif ($last_score == $num) {
	    #
	    # For many golfers, the current score needs to reflect the WHS.
	    # This gets their handicap ready for the 2020 season.
	    #
	    $usga = 0;
	    $date = "current";
	}

	@n = sort {$a <=> $b} @n;

	$hi = 0;

	#
	# Find out how many scores to use.
	#
	$use = nscores($num_scores, $usga);

	for ($x = 0; $x < $use; $x++) {
	    printf("%d: %.1f\n", $x, $n[$x]), if $debug;
	    $hi += $n[$x];
	}

	$hi /= $use;

	if ($usga) {
	    $hi *= $allowance;
	    $hi = (int($hi * 10) / 10);
	    $ph = int(($hi * $c{SF}->{slope} / 113) + 0.5);
	} else {
	    $hi = round($hi, 10);
	    $cd = ($c{$course}{course_rating} - $c{$course}{par});
	    $cd = round($cd, 10);
	    $ch = (($hi * ($c{$course}->{slope} / 113)) + $cd);
	    $ph = sprintf("%.0f", ($ch * $allowance));
	}

	#
	# If the date is 'current', this is the handicap index for the following week.
	# Otherwise we know what course the player played, their handicap for the course,
	# and their score for that week.
	#
	if ($date eq "current") {
	    printf ("%s:%s:%s:%.1f\n", $pn, $team, $date, $hi);
	} else {
	    printf ("%s:%s:%s:%s:%d:%.1f:%d\n", $pn, $team, $date, $course, $shot, $hi, $ph);
	}

	if ($last_score < 20) {
	    $last_score++;
	    $first_score = 0;
	} else {
	    $last_score++;
	    $first_score = ($last_score - 20);
	}
	$num_scores = ($last_score - $first_score);
    }
}
1;
