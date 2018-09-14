#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require 'tnfb_years.pl';
require 'courses.pl';

use Getopt::Long;

#
# Default to running stats on current year.
#
$start_year = 2018;
$end_year = 2018;
$cur_week = $start_week = 1;
$end_week = 15;
$stats_only = 0;
$player_stats = 0;
$tables = 0;
$html = 0;

GetOptions (
	"sy=s" => \$start_year,
	"ey=s" => \$end_year,
	"sw=s" => \$start_week,
	"ew=s" => \$end_week,
	"s" =>  \$stats_only,
	"p" =>  \$player_stats,
	"t" =>  \$tables,
	"h" =>  \$html,
	"d" => \$debug)
or die("Error in command line arguments\n");

$start_year = abs($start_year);
$end_year = abs($end_year);
$cur_week = $start_week = abs($start_week);
$end_week = abs($end_week);
undef(%y);
undef(%p);

#if ($html) {
	#print "<!DOCTYPE html>\n", if $html;
	#print "<html>\n", if $html;
#}

for (; ($start_year <= $end_year); $start_year++) {
	undef(%bt);
	undef(%et);

	for ($x = 200; $x < 400; $x++) {
		if (-e "golfers/$x") {
			print "$x: exists.\n", if $debug;
			&get_player_scores("golfers/$x");
		}
	}
	if ($stats_only) {
		&print_stats;
	}
	if ($tables) {
		&print_tables;
	}
}

if ($player_stats) {
	&print_player_stats;
}

sub print_stats {

    foreach $yp (sort keys %y) {

	print "$yp", if !$html;
	print " - Weeks $start_week through $end_week", if !$html &&
		(($end_week - $start_week) < 14) && (($end_week - $start_week) > 0);
	print " - Week $start_week", if !$html && ($start_week == $end_week);
	print ":\n", if !$html;

	print "<b><font color=\"green\">$yp</b></font>", if $html;
	print "&nbsp<b><font color=\"green\">- Weeks $start_week through $end_week</b></font></br", if $html &&
		(($end_week - $start_week) < 14) && (($end_week - $start_week) > 0);
	print "&nbsp<b><font color=\"green\">- Week $start_week</b></font>", if $html && ($start_week == $end_week);
	print "<b><font color=\"green\">:</b></font></br>", if $html;


	if ($y{$yp}{total_strokes} && $stats_only) {
	    printf("Total Posted scores: %d\n", $y{$yp}{total_scores}), if !$html;
	    printf("Total holes played: %d\n", ($y{$yp}{total_scores} * 9)), if !$html;
	    printf("Total Strokes = %d\n", $y{$yp}{total_strokes}), if !$html;
	    printf("League Stroke Average = %.2f\n",
		($y{$yp}{total_strokes} / $y{$yp}{total_scores})), if !$html;
	    printf("Total Eagles  = %d\n", $y{$yp}{total_eagles}), if !$html;
	    printf("Total Birdies = %d\n", $y{$yp}{total_birdies}), if !$html;
	    printf("Total Pars = %d\n", $y{$yp}{total_pars}), if !$html;
	    printf("Total Bogies = %d\n", $y{$yp}{total_bogies}), if !$html;
	    printf("Total Double Bogies = %d\n", $y{$yp}{total_db}), if !$html;
	    printf("Total Others = %d\n\n", $y{$yp}{total_other}), if !$html;

	    printf("Total Posted scores: <font color=\"green\">%d</font></br>\n", $y{$yp}{total_scores}), if $html;
	    printf("Total holes played: <font color=\"green\">%d</font></br>\n", ($y{$yp}{total_scores} * 9)), if $html;
	    printf("Total Strokes = <font color=\"green\">%d</font></br>\n", $y{$yp}{total_strokes}), if $html;
	    printf("League Stroke Average = <font color=\"green\">%.2f</font></br>\n",
		($y{$yp}{total_strokes} / $y{$yp}{total_scores})), if $html;
	    printf("Total Eagles  = <font color=\"green\">%d</font></br>\n", $y{$yp}{total_eagles}), if $html;
	    printf("Total Birdies = <font color=\"green\">%d</font></br>\n", $y{$yp}{total_birdies}), if $html;
	    printf("Total Pars = <font color=\"green\">%d</font></br>\n", $y{$yp}{total_pars}), if $html;
	    printf("Total Bogies = <font color=\"green\">%d</font></br>\n", $y{$yp}{total_bogies}), if $html;
	    printf("Total Double Bogies = <font color=\"green\">%d</font></br>\n", $y{$yp}{total_db}), if $html;
	    printf("Total Others = <font color=\"green\">%d</font></br></br>\n", $y{$yp}{total_other}), if $html;
	}
    }
}

sub print_tables {

    foreach $yp (sort keys %y) {
	if (%bt) {
	    print "<b>Birdie Table:</b></br>\n", if $html;
	    print "<head>\n<style>\n", if $html;
	    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
	    print "th, td {\n    text-align: left;\n}\n", if $html;
	    print "</style>\n</head>\n", if $html;
	    print "<table style=\"width:25\%\"></br>\n", if $html;
	    print "  <tr>\n    <th>Name</th>\n    <th>Birdies</th>\n  </tr>\n", if $html;
	    print "Birdie Table:\n", if !$html;
		foreach my $key (sort { $bt{$b} <=> $bt{$a} } keys %bt) {
		    printf "%-20s %4d\n", $key, $bt{$key}, if !$html;
		    print "  <tr>\n", if $html;
		    printf "    <td>%-20s</td>\n    <td>%4d</td>", $key, $bt{$key}, if $html;
		    print "  </tr>\n", if $html;
	        }
	    print "</table></br>", if $html;
	}
	print "\n", if !$html;

	if (%et) {
	    print "<b>Eagle Table:</b></br>\n", if $html;
	    print "<head>\n<style>\n", if $html;
	    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
	    print "th, td {\n    text-align: left;\n}\n", if $html;
	    print "</style>\n</head>\n", if $html;
	    print "<table style=\"width:25\%\"></br>\n", if $html;
	    print "  <tr>\n    <th>Name</th>\n    <th>Eagles</th>\n  </tr>\n", if $html;
	    print "Eagle Table:\n", if !$html;
	    foreach my $key (sort { $et{$b} <=> $et{$a} } keys %et) {
		printf "%-20s %4d\n", $key, $et{$key}, if !$html;
		print "  <tr>\n", if $html;
		printf "    <td>%-20s</td>\n    <td>%4d</td>", $key, $et{$key}, if $html;
		print "  </tr>\n", if $html;
	    }
	    print "</table>\n", if $html;
	}
	print "\n", if !$html;
	print "</br>", if $html;
    }
}

sub print_player_stats {

    foreach $x (sort keys %p) {

	#
	# Not all players play each year, so skip those that don't have posted scores.
	#
	if ($p{$x}{total_strokes} == 0) {
		next;
	}

	print "$x\n";
	print "$p{$x}{team}\n\n";

	print "Total Strokes = $p{$x}{total_strokes}\n\n";

	foreach $sc (keys %c) {
	    if ($p{$x}{$sc}{xplayed} == 0) {
		next;
	    }
            print "Played $sc: $p{$x}{$sc}{xplayed} times.\n";
	}

	print "\n";

	foreach $sc (keys %c) {

	    if ($p{$x}{$sc}{xplayed} == 0) {
		next;
	    }

	    print "$c{$sc}->{name}\n";

	    for ($h = 1; $h < 10; $h++) {

		printf("hole %d (par %d): Total shots: %3d  ", $h, $c{$sc}->{$h}, $p{$x}{$sc}{$h}{shots});

		printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($p{$x}{$sc}{$h}{shots} / $p{$x}{$sc}{xplayed}),
		    (($p{$x}{$sc}{$h}{shots} / $p{$x}{$sc}{xplayed}) - $c{$sc}->{$h}),
			$p{$x}{$sc}{$h}{b} ? $p{$x}{$sc}{$h}{b} : 0, $p{$x}{$sc}{$h}{e} ? $p{$x}{$sc}{$h}{e} : 0);
	    }
	    print "\n";
	}

    }
}

sub get_player_scores {

    my($fn) = @_;

    open(FD, $fn);

    # Get the players name/team.
    $name = <FD>;
    chop($name);

    ($first, $last, $team) = split(/:/, $name);

    if ($team eq "Sub") {
	#close (FD);
	#return;
    }

    $pn = $first . " " . $last;
    $p{$pn}{team} = $team;

    while (<FD>) {

	my ($year, $month, $day);

	chop;

	$num = ($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $n) = split(/:/, $_);

	#
	# Only provide stats with hole-by-hole data.
	#
	if ($num < 15) {
		next;
	}

	@score = ($o, $t, $th, $f, $fv, $s, $sv, $e, $n);

	#
	# Get the year, month and day of the current score.
	#
	($year, $month, $day) = split(/-/, $date);

	for ($cur_week = $start_week; $cur_week <= $end_week; $cur_week++) {
	    if (($start_year == $year) && ($dates{$start_year}{$cur_week} eq $date)) {

		print "$_\n", if $debug;

		$y{$start_year}{total_strokes} += $shot;
		$y{$start_year}{total_scores}++;

		$p{$pn}{total_strokes} += $shot;
		$p{$pn}{$course}{xplayed}++;

		for ($h = 1; $h < 10; $h++) {
		    $hole = abs(shift @score);
		    $p{$pn}{$course}{$h}{shots} += $hole;
		    if (($c{$course}->{$h} - $hole) < -2) { $y{$start_year}{total_other}++;  };
		    if (($c{$course}->{$h} - $hole) == -2) { $y{$start_year}{total_db}++;  };
		    if (($c{$course}->{$h} - $hole) == -1) { $y{$start_year}{total_bogies}++;  };
		    if (($c{$course}->{$h} - $hole) == 0) { $y{$start_year}{total_pars}++;  };
		    if (($c{$course}->{$h} - $hole) == 1) {
			$p{$pn}{$course}{$h}{b}++;
			$y{$start_year}{total_birdies}++;
			$bt{$pn} += 1;
		    }
		    if (($c{$course}->{$h} - $hole) == 2) {
			$p{$pn}{$course}{$h}{e}++;
			$y{$start_year}{total_eagles}++;
			$et{$pn} += 1;
		    };
		}
	    }
	}
    }
    close(FD);
}
