#! /usr/bin/perl

require 'tnfb_years.pl';

use Getopt::Long;

#
# Default to running stats on current year.
#
$start_year = 2018;
$end_year = 2018;
$start_week = 1;
$end_week = 15;

GetOptions (
	"sy=s" => \$start_year,
	"ey=s" => \$end_year,
	"sw=s" => \$start_week,
	"ew=s" => \$end_week,
	"s" =>  \$summary,
	"d" => \$debug)
or die("Error in command line arguments\n");

for ($y = $start_year; $y <= $end_year; $y++) {
	$yearly_scores = 0;
	for ($w = $start_week; $w <= $end_week; $w++) {
	    $weekly_scores = 0;
	    for ($x = 200; $x < 440; $x++) {
		if (-e $x) {
			&count_scores($x);
		}
	    }
	    if ($summary != 1) {
		print "$y, week $w scores -> $weekly_scores\n", if $weekly_scores;
		if ($weekly_scores > 0 && $weekly_scores < 32) {
		    print "\t\tLess than 32 scores.\n";
		}
	    }
	}
	print "$y: scores -> $yearly_scores\n";
}


sub count_scores {

	my($fn) = @_;

	print "filename = $fn\n", if $debug;

	open(FD, $fn);

	while (<FD>) {

		my ($x);

		chop;
		($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $n) = split(/:/, $_);

		$check_shot = 0;
		#
		# Only count scores that have hole-by-hole entries.
		#
		$check_shot = ($o + $t + $th + $f + $fv + $s + $sv + $e + $n);

		if ($check_shot && ($check_shot != $shot)) {
			print "$fn: Error inputting score!\n";
			print "$_\n";
			die;
		}

		if ($check_shot && ($dates{$y}{$w} eq $date)) {
		    print "$_\n", if $debug;
		    $yearly_scores += 1;
		    $weekly_scores += 1;
		}
	}
	close(FD);
}
