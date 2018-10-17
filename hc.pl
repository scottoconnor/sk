#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require "courses.pl";
require "hcroutines.pl";

use Getopt::Long;

$debug = 0;
$include_subs = 0;
$trend = 0;
$output = 1;
$pps = 0;	# Per player stats in their own file.

GetOptions (
        "t" =>  \$trend,
        "s" =>  \$pps,
        "d" => \$debug)
or die("Error in command line arguments\n");

for ($x = 200; $x < 400; $x++) {
	if (-e "golfers/$x") {
		if ($trend) {
			&gen_hc_trend("golfers/$x", $output);
		} else {
			&gen_hc("golfers/$x");
		}
		close(PT), if $pps;
	}
}

#foreach $p (sort keys %hc) {
	#print "$p $hc{$p}\n";
#}

sub gen_hc {
	my ($fn) = @_;
	my (@scores, $y, $hi, $use, @n, $pn);

	undef @n;

	open(FD, $fn);
	@scores = <FD>;
	close(FD);

	chomp($scores[0]);
	($first, $last, $team) = split(/:/, $scores[0]);

	if (($team eq "Sub") && ($include_subs == 0)) {
		return;
	}

	$pn = $first . " " . $last;

	shift @scores;

	$num = @scores;

	$out_filename = "/tmp/$first $last";

	if (-e $out_filename) {
		unlink $out_filename, if ($pps == 0);
	}

	open(PT, ">", "/tmp/$first $last"), if $pps;
	select PT, if $pps;

	#
	# If player has less than 5 scores, a handicap can not be generated.
	#
	if ($num < 5) {
		print "$first $last: Only $num scores, can not generate handicap\n", if $debug;
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
		($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
			split(/:/, $s);

		print "$course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni\n", if $debug;

		$n[$y] = ((($post - $par) * 113) / $slope);

		printf("date=%s: post=%d: differential: %.3f\n", $date, $post, $n[$y]), if $debug;

		#
		# First round to the nearest hundredth, then to the tenth.
		#
		$n[$y] = sprintf("%0.1f",$n[$y]);
		printf("date=%s: post=%d: differential: %.3f\n", $date, $post, $n[$y]), if $debug;

		$y++;
	}

	@n = sort {$a <=> $b} @n;

	$hi = 0;

	for ($y = 0; $y < $use; $y++) {
		printf("%d: %.1f\n", $y, $n[$y]), if $debug;
		$hi += $n[$y];
	}

	$hi /= $use;
	$hi *= 0.90;  # 90% is used for match play
	$hi = (int($hi * 10) / 10);

	if ($first eq "Scott") {
		#$hi = 5.9;
	}

	$sf = int(($hi * $c{SF}->{slope} / 113) + 0.5);
	$sb = int(($hi * $c{SB}->{slope} / 113) + 0.5);
	$nf = int(($hi * $c{NF}->{slope} / 113) + 0.5);
	$nb = int(($hi * $c{NB}->{slope} / 113) + 0.5);

	$hc{$pn} = $sf;
	printf ("%-16s - %4.1fN  HC = %2d\n", $pn, $hi, $sf);
	printf ("%-8s %-10s - %5.1fN  SF=%-3d SB=%-3d NF=%-3d NB=%-3d\n", $first, $last, $hi, $sf, $sb, $nf, $nb), if $debug;
}
