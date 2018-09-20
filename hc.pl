#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require "courses.pl";
require "hcroutines.pl";

use Getopt::Long;

$debug = 0;
$trend = 0;

GetOptions (
        "t" =>  \$trend,
        "d" => \$debug)
or die("Error in command line arguments\n");

for ($x = 200; $x < 400; $x++) {
	if (-e "golfers/$x") {
		&gen_hc("golfers/$x");
		if ($trend) {
			&gen_hc_trend("golfers/$x");
		}
	}
}

sub gen_hc {
	my ($fn) = @_;
	my (@scores, $x, $y, $hi, $use, @p, @n);

	undef @n;
	undef @p;

	open(FD, $fn);
	@scores = <FD>;
	close(FD);

	chomp($scores[0]);
	($first, $last, $team) = split(/:/, $scores[0]);

	if ($team eq "Sub") {
		return;
	}

	shift @scores;

	$num = @scores;

	#
	# If player has less than 5 scores, a handicap can not be generated.
	#
	if ($num < 5) {
		#print "$first $last: Only $num scores, can not generate handicap\n";
		return;
	}

	#
	# If the golfer has more than 20 scores, only grab the last 20.
	#
	if ($num > 20) {
		@scores = splice(@scores, ($num - 20), 20);
	}

	#
	# Using the USGA formula, determine how many scores will be used
	# to generate this player handicap.
	#
	$use = &nscores($num);

	$y = 0;
	foreach my $s (@scores) {

		chomp($s);
		($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $n) =
			split(/:/, $s);

		print "$course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $n\n", if $debug;

		#&check_scores($o, $t, $th, $f, $fv, $s, $sv, $e, $n);

		$p[$y] = ((($post - $par) * 113) / $slope);

		printf("date=%s: post=%d: differential: %.3f\n", $date, $post, $p[$y]), if $debug;

		#
		# First round to the nearest hundredth, then to the tenth.
		#
		$p[$y] = sprintf("%0.1f",$p[$y]);
		printf("date=%s: post=%d: differential: %.3f\n", $date, $post, $p[$y]), if $debug;

		$y++;
	}

	@n = sort {$a <=> $b} @p;

	$hi = 0;

	for ($x = 0; $x < $use; $x++) {
		printf("%d: %.1f\n", $x, $n[$x]), if $debug;
		$hi += $n[$x];
	}

	$hi /= $use;
	$hi *= 0.90;  # 90% is used for match play
	$hi = (int($hi * 10) / 10);

	if ($first eq "Scott") {
		#$hi = 5.5;
	}

	$sf = int(($hi * $c{SF}->{slope} / 113) + 0.5);
	$sb = int(($hi * $c{SB}->{slope} / 113) + 0.5);
	$nf = int(($hi * $c{NF}->{slope} / 113) + 0.5);
	$nb = int(($hi * $c{NB}->{slope} / 113) + 0.5);
	$hcave = int(($hi * $c{AVE}->{slope} / 113) + 0.5);

	printf ("%-8s %-10s - %5.1fN  HC=%-2d\n", $first, $last, $hi, $sf);
	#printf ("%-8s %-10s - %5.1fN  SF=%-3d SB=%-3d NF=%-3d NB=%-3d  AVE=%-3d\n", $first, $last, $hi, $sf, $sb, $nf, $nb, $hcave);
}


sub gen_hc_trend {
	my ($fn) = @_;
	my (@scores, $x, $y, $hi, $use, @p, @n);

	undef @n;
	undef @p;

	open(FD, $fn);
	@scores = <FD>;
	close(FD);

	chomp($scores[0]);
	($first, $last, $team) = split(/:/, $scores[0]);

	if ($team eq "Sub") {
		return;
	}

	shift @scores;

	$num = @scores;

	#
	# If player has less than 30 scores, do not generate a handicap trend.
	#
	if ($num < 30) {
		print "$first $last: Only $num scores, not enough to generate a trend.\n";
		return;
	}

	#
	# With a handicap trend, we will always have at least 20 scores.
	#
	$use = &nscores($num);

	$y = 0; $first_score = 0; $last_score = 20;

	while ($last_score <= $num) {
		$y = 0; undef @p; undef @n;
		while ($first_score < $last_score) {

			$s = $scores[$first_score];
			chomp($s);
			($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $n) =
				split(/:/, $s);
			$p[$y] = ((($post - $par) * 113) / $slope);
			$p[$y] = sprintf("%0.1f",$p[$y]);

			printf("date=%s: post=%d: differential: %.1f\n", $date, $post, $p[$y]), if $debug;
			#print "first score = $first_score, last score = $last_score\n";
			$first_score++;
			$y++;
		}
		@n = sort {$a <=> $b} @p;

		$hi = 0;

		for ($x = 0; $x < $use; $x++) {
			printf("%d: %.1f\n", $x, $n[$x]), if $debug;
			$hi += $n[$x];
		}

		$hi /= $use;
		$hi *= 0.90;  # 90% is used for match play
		$hi = (int($hi * 10) / 10);

		$sf = int(($hi * $c{SF}->{slope} / 113) + 0.5);

		#printf ("%-9s:  %-10s %-8s - %5.1fN  HC=%-3d\n", $date, $last, $first, $hi, $sf);
		printf ("%-9s:  %5.1fN  HC=%-3d\n", $date, $hi, $sf);
		$last_score++;
		$first_score = ($last_score - 20);
	}
}

sub check_score_order {
	my ($num, @ls) = @_;
	my ($x);

	for ($x = 0; $x < $num; $x++) {
		chomp($ls[$x]);
		($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $n) =
			split(/:/, $ls[$x]);
		$players{$date}->{c} = $course;
		$players{$date}->{par} = $par;
		$players{$date}->{slope} = $slope;
		$players{$date}->{shot} = $shot;
		$players{$date}->{post} = $post;
		$players{$date}->{one} = $o;
		$players{$date}->{two} = $t;
		$players{$date}->{three} = $th;
		$players{$date}->{four} = $f;
		$players{$date}->{five} = $fv;
		$players{$date}->{six} = $s;
		$players{$date}->{seven} = $sv;
		$players{$date}->{eight} = $e;
		$players{$date}->{nine} = $n;
	}
	foreach my $sk (sort keys %players) {
		printf "%-8s %s\n", $sk, $players{$sk}->{c};
	}
}

sub combine_scores {
	my (@s) = @_;
	my $n = @s;

	print"Start: $n";
	for (; $n >=0; $n--) {
		chomp($s[$n]);
		print "@s[$n]\n";
	}
	print"End: $n\n";

	return(@s);
}
