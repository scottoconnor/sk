#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require 'tnfb_years.pl';

use Getopt::Long;

#
# Pars for each hole on each course.
#
%c = (
	SF => {
		onep => 4, twop => 4, threep => 3, fourp => 4, fivep => 5, sixp => 5,
		sevenp => 3, eightp => 4, ninep => 4
	},
	SB => {
		onep => 5, twop => 3, threep => 4, fourp => 4, fivep => 5, sixp => 3,
		sevenp => 4, eightp => 3, ninep => 5
	},
	NF => {
		onep => 5, twop => 4, threep => 4, fourp => 4, fivep => 5, sixp => 3,
		sevenp => 4, eightp => 3, ninep => 4
	},
	NB => {
		onep => 4, twop => 4, threep => 5, fourp => 3, fivep => 4, sixp => 4,
		sevenp => 3, eightp => 4, ninep => 5,
	},
);

#
# Players data structure.
#
%player = (
	Name => {
		firstname, lastname, team,
	},
	SF => {
		xplayed, one, two, three, four, five, six, seven, eight, nine,
		oneb, twob, threeb, fourb, fiveb, sixb, sevenb, eightb, nineb,
		onee, twoe, threee, foure, fivee, sixe, sevene, eighte, ninee,
	},
	SB => {
		xplayed, one, two, three, four, five, six, seven, eight, nine,
		oneb, twob, threeb, fourb, fiveb, sixb, sevenb, eightb, nineb,
		onee, twoe, threee, foure, fivee, sixe, sevene, eighte, ninee,
	},
	NF => {
		xplayed, one, two, three, four, five, six, seven, eight, nine,
		oneb, twob, threeb, fourb, fiveb, sixb, sevenb, eightb, nineb,
		onee, twoe, threee, foure, fivee, sixe, sevene, eighte, ninee,
	},
	NB => {
		xplayed, one, two, three, four, five, six, seven, eight, nine,
		oneb, twob, threeb, fourb, fiveb, sixb, sevenb, eightb, nineb,
		onee, twoe, threee, foure, fivee, sixe, sevene, eighte, ninee,
	},
);

#
# Default to running stats on current year.
#
$start_year = 2018;
$end_year = 2018;
$cur_week = $start_week = 1;
$end_week = 15;
$stats_only = 0;
$yearly_stats = 0;
$weekly_stats = 0;
$html = 0;

GetOptions (
	"sy=s" => \$start_year,
	"ey=s" => \$end_year,
	"sw=s" => \$start_week,
	"ew=s" => \$end_week,
	"s" =>  \$stats_only,
	"i" =>  \$player_stats,
	"y" =>  \$yearly_stats,
	"w" =>  \$weekly_stats,
	"h" =>  \$html,
	"d" => \$debug)
or die("Error in command line arguments\n");

$start_year = abs($start_year);
$end_year = abs($end_year);
$cur_week = $start_week = abs($start_week);
$end_week = abs($end_week);

if ($html) {
	print "<!DOCTYPE html>\n", if $html;
	print "<html>\n", if $html;
}


if (!$yearly_stats) {
	foreach my $key (sort keys %dates) {
		for ($xx = 1; $xx <= 15; $xx++) {
			print "year = $key - $dates{$key}{$xx}\n";
		}
	}
}

for (; $yearly_stats && ($start_year <= $end_year); $start_year++) {
	$total_strokes = 0;
	$total_birdies = 0;
	$total_eagles = 0;
	$total_scores = 0;
	undef(%bp);
	undef(%ep);

	print "$start_year:\n", if !$html && !$weekly_stats;
	print "$start_year - Week $cur_week:\n", if !$html && $weekly_stats;

	print "<b><font color=\"green\">$start_year:</b></font></br>\n", if $html && !$weekly_stats;
	print "<b><font color=\"green\">$start_year - Week $cur_week</b></font></br>\n", if $html && $weekly_stats;

	for ($x = 200; $x < 440; $x++) {
		if (-e $x) {
			#print "$x: exists.\n";
			&player_stat($x);
		}
	}
	if ($total_strokes) {
	printf("Total Posted scores: %d\n", $total_scores), if !$html;
	printf("Total holes played: %d\n", ($total_scores * 9)), if !$html;
	printf("Total Strokes = %d\n", $total_strokes), if !$html;
	printf("League Stroke Average = %.2f\n", ($total_strokes / $total_scores)), if !$html;
	printf("Total Birdies = %d\n", $total_birdies), if !$html;
	printf("Total Eagles  = %d\n", $total_eagles), if !$html;
	}

	printf("Total Posted scores: <font color=\"green\">%d</font></br>\n", $total_scores), if $html;
	printf("Total holes played: <font color=\"green\">%d</font></br>\n", ($total_scores * 9)), if $html;
	printf("Total Strokes = <font color=\"green\">%d</font></br>\n", $total_strokes), if $html;
	printf("League Stroke Average = <font color=\"green\">%.2f</font></br>\n", ($total_strokes / $total_scores)), if $html;
	printf("Total Birdies = <font color=\"green\">%d</font></br>\n", $total_birdies), if $html;
	printf("Total Eagles  = <font color=\"green\">%d</font></br>\n", $total_eagles), if $html;


	if ($player_stats) {
	    if (%bp) {
	    print "\n</br><b>Birdie Table:</b></br>\n", if $html;
	    print "<head>\n<style>\n", if $html;
	    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
	    print "th, td {\n    text-align: left;\n}\n", if $html;
	    print "</style>\n</head>\n", if $html;
	    print "<table style=\"width:25\%\"></br>\n", if $html;
	    print "  <tr>\n    <th>Name</th>\n    <th>Birdies</th>\n  </tr>\n", if $html;
	    print "\nBirdie Table:\n", if !$html;
	    foreach my $key (sort { $bp{$b} <=> $bp{$a} } keys %bp) {
		printf "%-20s %4d\n", $key, $bp{$key}, if !$html;
		print "  <tr>\n", if $html;
		printf "    <td>%-20s</td>\n    <td>%4d</td>", $key, $bp{$key}, if $html;
		print "  </tr>\n", if $html;
	    }
	    print "</table>\n", if $html;
	    }
	    if (%ep) {
	    print "\n</br><b>Eagle Table:</b></br>\n", if $html;
	    print "<head>\n<style>\n", if $html;
	    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
	    print "th, td {\n    text-align: left;\n}\n", if $html;
	    print "</style>\n</head>\n", if $html;
	    print "<table style=\"width:25\%\"></br>\n", if $html;
	    print "  <tr>\n    <th>Name</th>\n    <th>Eagles</th>\n  </tr>\n", if $html;
	    print "\nEagle Table:\n", if !$html;
	    foreach my $key (sort { $ep{$b} <=> $ep{$a} } keys %ep) {
		printf "%-20s %4d\n", $key, $ep{$key}, if !$html;
		print "  <tr>\n", if $html;
		printf "    <td>%-20s</td>\n    <td>%4d</td>", $key, $ep{$key}, if $html;
		print "  </tr>\n", if $html;
	    }
	    print "</table>\n", if $html;
	    }
	    print "\n\n";
	    print "</br></br>", if $html;
	}
}

sub player_stat {

my($fn) = @_;

undef $course;
undef %player;

$player{SF}->{xplayed} = 0;
$player{SB}->{xplayed} = 0; 
$player{NF}->{xplayed} = 0;
$player{NB}->{xplayed} = 0;

#print "filename = $fn\n";

open(FD, $fn);

# Get the players name/team.
$name = <FD>;
chop($name);

($first, $last, $team) = split(/:/, $name);

if ($team eq "Sub") {
	#return;
}

$player{Name}->{firstname} = $first;
$player{Name}->{lastname} = $last;
$player{Name}->{team} = $team;

$strokes = 0;

while (<FD>) {

	my ($year, $month, $day);

	chop;
	($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $n) = split(/:/, $_);

	$check_shot = 0;
	#
	# Only count scores that have hole-by-hole entries.
	#
	$check_shot = ($o + $t + $th + $f + $fv + $s + $sv + $e + $n);

	#
	# Get the year, month and day of the current score.
	#
	($year, $month, $day) = split(/-/, $date);

	for ($cur_week = $start_week; $cur_week <= $end_week; $cur_week++) {
	    if ($check_shot && ($start_year == $year) && ($dates{$start_year}{$cur_week} eq $date)) {

		print "$_\n", if $debug;

		$strokes += $shot;
		$player{$course}->{xplayed}++;

		$player{$course}->{one} += $o;
		if (($c{$course}->{onep}) - $o == 1) { $player{$course}->{oneb}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{onep}) - $o == 2) { $player{$course}->{onee}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{two} += $t;
		if (($c{$course}->{twop}) - $t == 1) { $player{$course}->{twob}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{twop}) - $t == 2) { $player{$course}->{twoe}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{three} += $th;
		if (($c{$course}->{threep}) - $th == 1) { $player{$course}->{threeb}++; $total_birdies++; $bp{$first . " " . $last} += 1;};
		if (($c{$course}->{threep}) - $th == 2) { $player{$course}->{threee}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{four} += $f;
		if (($c{$course}->{fourp}) - $f == 1) { $player{$course}->{fourb}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{fourp}) - $f == 2) { $player{$course}->{foure}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{five} += $fv;
		if (($c{$course}->{fivep}) - $fv == 1) { $player{$course}->{fiveb}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{fivep}) - $fv == 2) { $player{$course}->{fivee}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{six} += $s;
		if (($c{$course}->{sixp}) - $s == 1) { $player{$course}->{sixb}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{sixp}) - $s == 2) { $player{$course}->{sixe}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{seven} += $sv;
		if (($c{$course}->{sevenp}) - $sv == 1) { $player{$course}->{sevenb}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{sevenp}) - $sv == 2) { $player{$course}->{sevene}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{eight} += $e;
		if (($c{$course}->{eightp}) - $e == 1) { $player{$course}->{eightb}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{eightp}) - $e == 2) { $player{$course}->{eighte}++; $total_eagles++; $ep{$first . " " . $last} += 1; };

		$player{$course}->{nine} += $n;
		if (($c{$course}->{ninep}) - $n == 1) { $player{$course}->{nineb}++; $total_birdies++; $bp{$first . " " . $last} += 1; };
		if (($c{$course}->{ninep}) - $n == 2) { $player{$course}->{ninee}++; $total_eagles++; $ep{$first . " " . $last} += 1; };
	    }
	}
}

if ($strokes == 0) {
	close(FD);
	return;
}

$total_strokes += $strokes;
$total_scores += ($player{SF}->{xplayed} + $player{SB}->{xplayed} + $player{NF}->{xplayed} + $player{NB}->{xplayed});

if ($stats_only) {
	close(FD);
	return;
}

print "Name: $player{Name}->{firstname} $player{Name}->{lastname}\n";
print "Team: $player{Name}->{team}\n\n";

print "Played South Front $player{SF}->{xplayed} times.\n";
print "Played South Back  $player{SB}->{xplayed} times.\n";
print "Played North Front $player{NF}->{xplayed} times.\n";
print "Played North Back  $player{NB}->{xplayed} times.\n\n";

@c = ('SF', 'SB', 'NF', 'NB');

print "Total shots = $strokes\n\n";

foreach (@c) {

	$hole = 1;
	if ($_ eq 'SB' || $_ eq 'NB') {
		$hole += 9;
	}

	if ($player{$_}{xplayed}) {

		if ($_ eq "SF") {
			print "South Front:\n";
		} elsif ($_ eq "SB") {
			print "South Back:\n";
		} elsif ($_ eq "NF") {
			print "North Front:\n";
		} elsif ($_ eq "NB") {
			print "North Back:\n";
		}


	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{onep}, $player{$_}->{one});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{one} / $player{$_}->{xplayed}),
	    (($player{$_}->{one} / $player{$_}->{xplayed}) - $c{$_}->{onep}),
		$player{$_}->{oneb} ? $player{$_}->{oneb} : 0, $player{$_}->{onee} ? $player{$_}->{onee} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{twop}, $player{$_}->{two});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{two} / $player{$_}->{xplayed}),
	    (($player{$_}->{two} / $player{$_}->{xplayed}) - $c{$_}->{twop}),
		$player{$_}->{twob} ? $player{$_}->{twob} : 0, $player{$_}->{twoe} ? $player{$_}->{twoe} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{threep}, $player{$_}->{three});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{three} / $player{$_}->{xplayed}),
	    (($player{$_}->{three} / $player{$_}->{xplayed}) - $c{$_}->{threep}),
		$player{$_}->{threeb} ? $player{$_}->{threeb} : 0, $player{$_}->{threee} ? $player{$_}->{threee} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{fourp}, $player{$_}->{four});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{four} / $player{$_}->{xplayed}),
	    (($player{$_}->{four} / $player{$_}->{xplayed}) - $c{$_}->{fourp}),
		$player{$_}->{fourb} ? $player{$_}->{fourb} : 0, $player{$_}->{foure} ? $player{$_}->{foure} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{fivep}, $player{$_}->{five});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{five} / $player{$_}->{xplayed}),
	    (($player{$_}->{five} / $player{$_}->{xplayed}) - $c{$_}->{fivep}),
		$player{$_}->{fiveb} ? $player{$_}->{fiveb} : 0, $player{$_}->{fivee} ? $player{$_}->{fivee} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{sixp}, $player{$_}->{six});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{six} / $player{$_}->{xplayed}),
	    (($player{$_}->{six} / $player{$_}->{xplayed}) - $c{$_}->{sixp}),
		$player{$_}->{sixb} ? $player{$_}->{sixb} : 0, $player{$_}->{sixe} ? $player{$_}->{sixe} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{sevenp}, $player{$_}->{seven});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{seven} / $player{$_}->{xplayed}),
	    (($player{$_}->{seven} / $player{$_}->{xplayed}) - $c{$_}->{sevenp}),
		$player{$_}->{sevenb} ? $player{$_}->{sevenb} : 0, $player{$_}->{sevene} ? $player{$_}->{sevene} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{eightp}, $player{$_}->{eight});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n", ($player{$_}->{eight} / $player{$_}->{xplayed}),
	    (($player{$_}->{eight} / $player{$_}->{xplayed}) - $c{$_}->{eightp}),
		$player{$_}->{eightb} ? $player{$_}->{eightb} : 0, $player{$_}->{eighte} ? $player{$_}->{eighte} : 0);

	printf("hole %d (par %d): Total shots: %3d, ", $hole++, $c{$_}->{ninep}, $player{$_}->{nine});
	printf("ave = %.2f, %.2f vs. par, B: %d, E: %d\n\n", ($player{$_}->{nine} / $player{$_}->{xplayed}),
	    (($player{$_}->{nine} / $player{$_}->{xplayed}) - $c{$_}->{ninep}),
		$player{$_}->{nineb} ? $player{$_}->{nineb} : 0, $player{$_}->{ninee} ? $player{$_}->{ninee} : 0);
	}

}

close(FD);
}
