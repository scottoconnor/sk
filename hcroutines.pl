#! /usr/bin/perl
#
# Copyright (c) 2018, 2020 Scott O'Connor
#

#
# Determine how many scores to use.
#
# Starting in 2020, the World Handicap System was implemented.  The number
# of scores used is different than the previous USGA handicap formula.
# Need to keep the USGA method for when a players trend is calculated.
#
sub nscores {
    my ($x, $year) = @_;

    if ($year >= 2020) {
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
    } else {
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
    }
}

#
# Rounds to the nearest thousands position.
#
sub round_thousands {
    my ($r) = @_;

    $r *= 1000;
    $r = int($r + 0.5);
    $r /= 1000;
    return ($r);
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

sub gen_hc_trend {
	my ($fn, $output) = @_;
	my (@scores, $x, $y, $hi, $use, @n, $num_scores, $hc_year);

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
	# Set handicap year to 1996.  Logic will change it below.
	#
	$hc_year = 1996;

	if (($use = nscores($num, $hc_year)) == 0) {
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
			# make sure the WHS formula is used. $hc_year does that for us.
			#
			($year, $month, $day) = split(/-/, $date);
			$hc_year = ($year > $hc_year) ? $year : $hc_year;

			$n[$y] = ((113 / $slope) * ($post - $course_rating));

			if ($shot > 75) {
			    $n[$y] /= 2;
			}
			$n[$y] = sprintf("%0.1f", $n[$y]);

			printf("date=%s: post=%d: differential: %.1f\n", $date, $post, $n[$y]), if $debug;

			$first_score++;
			$y++;
		}

		if ($last_score < $num) {
		    $s = $scores[$last_score];
		    chomp($s);
		    ($course, $course_rating, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
			split(/:/, $s);
		} elsif ($last_score == $num) {
			$date = "current";
		}

		@n = sort {$a <=> $b} @n;

		$hi = 0;

		#
		# Find out how many scores to use.
		#
		$use = nscores($num_scores, $hc_year);

		for ($x = 0; $x < $use; $x++) {
			printf("%d: %.1f\n", $x, $n[$x]), if $debug;
			$hi += $n[$x];
		}

		$hi /= $use;

		if ($year < 2020) {
		    $hi *= 0.90;  # 90% is used for match play
		    $hi = (int($hi * 10) / 10);
		    $sf = int(($hi * $c{SF}->{slope} / 113) + 0.5);
		    $sb = int(($hi * $c{SB}->{slope} / 113) + 0.5);
		    $nf = int(($hi * $c{NF}->{slope} / 113) + 0.5);
		    $nb = int(($hi * $c{NB}->{slope} / 113) + 0.5);
		} elsif ($year >= 2020) {
		    $hi = round_tenth($hi);
		    $sf = (($hi * ($c{SF}->{slope} / 113)) + ($c{SF}{course_rating} - $c{SF}{par}));
		    $sf = sprintf("%.0f", ($sf * 0.90));
		    $sb = (($hi * ($c{SB}->{slope} / 113)) + ($c{SB}{course_rating} - $c{SB}{par}));
		    $sb = sprintf("%.0f", ($sb * 0.90));
		    $nf = (($hi * ($c{NF}->{slope} / 113)) + ($c{NF}{course_rating} - $c{NF}{par}));
		    $nf = sprintf("%.0f", ($nf * 0.90));
		    $nb = (($hi * ($c{NB}->{slope} / 113)) + ($c{NB}{course_rating} - $c{NB}{par}));
		    $nb = sprintf("%.0f", ($nb * 0.90));
		}

		printf ("%s:%s:%s:%.1f:%d\n", $pn, $team, $date, $hi, $sf), if $output;

		$p{$pn}{$date}{hc} = $sf, if ($output == 0);

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
