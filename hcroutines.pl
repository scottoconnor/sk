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

sub gen_hc_trend {
	my ($fn, $output) = @_;
	my (@scores, $x, $y, $hi, $use, @n);

	undef @n;

	open(FD, $fn);
	@scores = <FD>;
	close(FD);

	chomp($scores[0]);
	($pn, $team, $active) = split(/:/, $scores[0]);

	shift @scores;

	$num = @scores;

	#
	# If player has less than 5 scores, do not generate a handicap trend.
	#
	if ($num < 5) {
		print "$pn: Only $num scores, not enough to generate a trend.\n", if $debug;
		return;
	}

	$first_score = 0; $last_score = 5;

	#
	# Find out how many scores to use.
	#
	$use = &nscores($num);

	while ($last_score <= $num) {
		$y = 0; undef @n;
		while ($first_score < $last_score) {

			$s = $scores[$first_score];
			chomp($s);
			($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
				split(/:/, $s);

			($year, $month, $day) = split(/-/, $date);
			$n[$y] = ((($post - $par) * 113) / $slope);
			if ($shot > 75) {
			    $n[$y] /= 2;
			}
			$n[$y] = sprintf("%0.1f", $n[$y]);

			printf("date=%s: post=%d: differential: %.1f\n", $date, $post, $n[$y]), if $debug;
			print "first score = $first_score, last score = $last_score\n", if $debug;
			$first_score++;
			$y++;
		}

		if ($last_score < $num) {
		    $s = $scores[$last_score];
		    chomp($s);
		    ($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
			split(/:/, $s);
		} elsif ($last_score == $num) {
			$date = "current";
		}

		@n = sort {$a <=> $b} @n;

		$hi = 0;

		for ($x = 0; $x < $use; $x++) {
			printf("%d: %.1f\n", $x, $n[$x]), if $debug;
			$hi += $n[$x];
		}

		$hi /= $use;
		$hi *= 0.90;  # 90% is used for match play
		$hi = (int($hi * 10) / 10);

		$sf = int(($hi * $c{SF}->{slope} / 113) + 0.5);

		printf ("%s:%s:%.1f:%d\n", $pn, $date, $hi, $sf), if $output;

		$p{$pn}{$date}{hc} = $sf, if ($output == 0);

		if ($last_score < 20) {
			$last_score++;
			$first_score = 0;
		} else {
			$last_score++;
			$first_score = ($last_score - 20);
		}
	}
}
1;
