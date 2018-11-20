#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require "courses.pl";
require "hcroutines.pl";
require "tnfb.pl";

use Getopt::Long;

$debug = 0;
$include_subs = 1;
$trend = 0;
$output = 1;

GetOptions (
        "t" =>  \$trend,
        "d" => \$debug)
or die("Error in command line arguments\n");

#
# Only used files processed by skcon.pl (ScoreKeeper Convert).
#
opendir($dh, "./golfers") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ eq '.' or $_ eq '..') {
	next;
    }
    if ($_ =~ /(\d{4}$)/) {
	push @golfer_list, $_;
    }
}
closedir ($dh);

@golfer_list = sort @golfer_list;

while ($fna = shift @golfer_list) {
	if ($trend) {
		&gen_hc_trend("golfers/$fna", $output);
	} else {
		&gen_hc("golfers/$fna");
	}
}

if ($trend == 0) {
    $cnt = 1;
    foreach $p (sort { $golfers{$a}{team} cmp $golfers{$b}{team} } (keys(%golfers))) {
	if ($golfers{$p}{team} eq "Sub") {
		next;
	}
	$gn = $golfers{$p}{first} . " " . $golfers{$p}{last};
	printf("%-25s: %-17s: %4.1fN / %d\n", $golfers{$p}{team}, $gn, $hc{$gn}{hi}, $hc{$gn}{hc});
	$cnt++;
	print "\n", if (($cnt % 2) && ($cnt < 32));
    }

    print "\014\n";
    print "Subs\n";
    foreach $p (sort { $golfers{$a}{last} cmp $golfers{$b}{last} } (keys(%golfers))) {
	if ($golfers{$p}{team} ne "Sub") {
		next;
	}
	$gn = $golfers{$p}{first} . " " . $golfers{$p}{last};
	if (defined($hc{$gn}{hc})) {
		printf("%-17s: %4.1fN / %d\n", $gn, $hc{$gn}{hi}, $hc{$gn}{hc});
	}
    }
}

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

		if ($shot > 75) {
		    $n[$y] /= 2;
		}

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

	$hc{$pn}{hi} = $hi;
	$hc{$pn}{hc} = $sf;
	#printf ("%-16s - %4.1fN  HC = %2d\n", $pn, $hi, $sf);
	printf ("%-8s %-10s - %5.1fN  SF=%-3d SB=%-3d NF=%-3d NB=%-3d\n", $first, $last, $hi, $sf, $sb, $nf, $nb), if $debug;
}
