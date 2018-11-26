#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require 'tnfb_years.pl';
require 'courses.pl';
require 'hcroutines.pl';

use Getopt::Long;

#
# Default to running stats on current year.
#
$start_year = $end_year = (1900 + (localtime)[5]);
$cur_week = $start_week = 1;
$end_week = 15;
$all_time = 0;
$vhc = 0;
$top_gun = 0;
$stats = 0;
$include_subs = 0;
$player_stats = 0;
$tables = 0;
$output = 0;
$html = 0;

GetOptions (
	"sy=i" => \$start_year,
	"ey=i" => \$end_year,
	"sw=i" => \$start_week,
	"ew=i" => \$end_week,
	"is" => \$include_subs,
	"vhc" => \$vhc,
	"at" => \$all_time,
	"s" =>  \$stats,
	"p" =>  \$player_stats,
	"t" =>  \$tables,
	"g" =>  \$top_gun,
	"h" =>  \$html,
	"d" => \$debug)
or die("Error in command line arguments\n");

if ($all_time) {
	$start_year = 1997;
}

if ($stats || $tables) {
	$include_subs = 1;
}

$cur_week = $start_week;

undef(%y);
undef(%p);

#
# Load the players handcaip trend in case they are needed.
#
&get_player_trend();

#
# Open the golfers directory and only read the files that
# have been processed via skcon.pl (ScoreKeeper convert).
#
opendir($dh, "./golfers") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ =~ /(\d{4}$)/) {
	push @global_golfer_list, $_;
    }
}
closedir ($dh);

@global_golfer_list = sort @global_golfer_list;

#
# First get all the players scores/stats for the requested years/weeks.
# Calling get_player_scores will load up the hashes:
# 	%p  with all the player data on a per player basis
# 	%y  with all the yearly data on a per year basis
#
# After we get that, the other routines can use that data to generate stats.
#
for (; ($start_year <= $end_year); $start_year++) {
	@golfer_list = @global_golfer_list;
	while ($fna = shift @golfer_list) {
		&get_player_scores("golfers/$fna");
	}
}

#
# Print out the the players score verses their handicap on a weekly
# basis and average for the years specified.
#
if ($vhc) {
    foreach $pn (keys %p) {
	if (($p{$pn}{total_strokes} == 0) || ($p{$pn}{total_rounds} == 0) ||
	    (($p{$pn}{team} eq "Sub") && ($include_subs == 0))) {
	    next;
	}

	foreach $yp (sort keys %y) {
	    foreach $w (1..$end_week) {
		if ($p{$pn}{$dates{$yp}{$w}}{score} && defined($p{$pn}{$dates{$yp}{$w}}{hc})) {
		    $p{$pn}{diff} += (($p{$pn}{$dates{$yp}{$w}}{score} - $p{$pn}{$dates{$yp}{$w}}{hc}) - 36);
		    printf("%-17s: year %-4d week %-2s shot %d, hc %2d, net %d, diff %d\n", $pn, $yp, $w, $p{$pn}{$dates{$yp}{$w}}{score},
			$p{$pn}{$dates{$yp}{$w}}{hc}, ($p{$pn}{$dates{$yp}{$w}}{score} - $p{$pn}{$dates{$yp}{$w}}{hc}),
			    (($p{$pn}{$dates{$yp}{$w}}{score} - $p{$pn}{$dates{$yp}{$w}}{hc}) - 36));
		} elsif ($p{$pn}{$dates{$yp}{$w}}{score} && !defined($p{$pn}{$dates{$yp}{$w}}{hc})) {
		    $p{$pn}{total_rounds}--;
		}
	    }
	}
	$p{$pn}{avediff} = ($p{$pn}{diff} / $p{$pn}{total_rounds}), if ($p{$pn}{total_rounds} > 0);
	print "\n", if ($p{$pn}{total_rounds} > 0);
    }

    foreach $pn (sort { $p{$a}{avediff} <=> $p{$b}{avediff} } (keys(%p))) {
	if ($p{$pn}{total_strokes} == 0 || (($p{$pn}{team} eq "Sub") && ($include_subs == 0))) {
	    next;
	}
	printf("%-25s %-17s: Ave = %.2f \(total rounds %d\)\n", $p{$pn}{team},
	    $pn, $p{$pn}{avediff}, $p{$pn}{total_rounds});
    }
}

if ($top_gun) {
    my $has_rounds = 0;
    foreach $pn (keys %p) {
	if (($p{$pn}{total_strokes} == 0) || ($p{$pn}{total_rounds} == 0) ||
            (($p{$pn}{team} eq "Sub") && ($include_subs == 0))) {
            next;
        }

        foreach $yp (sort keys %y) {
            foreach $w (1..$end_week) {
		if ($p{$pn}{$dates{$yp}{$w}}{score} != 0 && $p{$pn}{$dates{$yp}{$w}}{score} < 40) {
		    printf("%-17s: year %-4d week %-2s shot %d\n", $pn, $yp, $w, $p{$pn}{$dates{$yp}{$w}}{score});
		    $has_rounds = 1;
		}
	    }
	}
	if ($has_rounds) {
	    print "\n";
	    $has_rounds = 0;
	}
    }
}

#
# Now print out the data for those years/weeks.
#
# The years are printed in descending order.
#
foreach $yp (reverse sort keys %y) {
    if ($stats) {
	&print_stats($yp);
    }
    if ($tables) {
	&print_tables($yp);
    }
}

#
# Print out player's hole-by-hole stats if requested.
#
if ($player_stats) {
	&print_player_stats;
}

if ($all_time) {
    print "<b>All Time Eagles Table:</b></br>\n", if $html;
    print "<head>\n<style>\n", if $html;
    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
    print "th, td {\n    text-align: left;\n}\n", if $html;
    print "</style>\n</head>\n", if $html;
    print "<table style=\"width:40\%\"></br>\n", if $html;
    print "  <tr>\n    <th>Name</th>\n    <th>Eagles</th>\n    <th>Eagles per 9-holes</th>\n  </tr>\n", if $html;
    print "All Time Eagles Table:\n", if !$html;
    foreach $key (sort { $p{$b}{te} <=> $p{$a}{te} } (keys(%p))) {
	if ($p{$key}{te} == 0 || ($p{$key}{total_rounds} < 30)) {
	    next;
	}
	printf("%-17s: %d\t(%.3f eagles per 9 holes)\n", $key, $p{$key}{te}, ($p{$key}{te} / $p{$key}{total_rounds})), if !$html;
	print "  <tr>\n", if $html;
	printf("    <td>%-20s</td>\n    <td>%4d</td>    <td>%.3f", $key, $p{$key}{te}, ($p{$key}{te} / $p{$key}{total_rounds})), if $html;
	print "  </tr>\n", if $html;
    }

    print "\n", if !$html;
    print "</table></br>", if $html;
    print "<b>All Time Birdie Table:</b></br>\n", if $html;
    print "<head>\n<style>\n", if $html;
    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
    print "th, td {\n    text-align: left;\n}\n", if $html;
    print "</style>\n</head>\n", if $html;
    print "<table style=\"width:40\%\"></br>\n", if $html;
    print "  <tr>\n    <th>Name</th>\n    <th>Birdies</th>\n    <th>Birdies per 9-holes</th>\n  </tr>\n", if $html;
    print "All Time Birdie Table:\n", if !$html;
    foreach $key (sort { $p{$b}{tb} <=> $p{$a}{tb} } (keys(%p))) {
	if ($p{$key}{tb} == 0 || ($p{$key}{total_rounds} < 30)) {
	    next;
	}
	printf("%-17s: %d\t(%.2f birdies per 9 holes)\n", $key, $p{$key}{tb}, ($p{$key}{tb} / $p{$key}{total_rounds})), if !$html;
	print "  <tr>\n", if $html;
	printf("    <td>%-20s</td>\n    <td>%4d</td>    <td>%.2f", $key, $p{$key}{tb}, ($p{$key}{tb} / $p{$key}{total_rounds})), if $html;
	print "  </tr>\n", if $html;
    }
    print "\n", if !$html;
    print "</table></br>", if $html;

    print "<b>All Time Par Table:</b></br>\n", if $html;
    print "<head>\n<style>\n", if $html;
    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
    print "th, td {\n    text-align: left;\n}\n", if $html;
    print "</style>\n</head>\n", if $html;
    print "<table style=\"width:40\%\"></br>\n", if $html;
    print "  <tr>\n    <th>Name</th>\n    <th>Pars</th>\n    <th>Pars per 9-holes</th>\n  </tr>\n", if $html;
    print "All Time Par Table:\n", if !$html;
    foreach $key (sort { $p{$b}{tp} <=> $p{$a}{tp} } (keys(%p))) {
	if ($p{$key}{tp} == 0 || ($p{$key}{total_rounds} < 30)) {
	    next;
	}
	printf("%-17s: %d\t(%.2f pars per 9 holes)\n", $key, $p{$key}{tp}, ($p{$key}{tp} / $p{$key}{total_rounds})), if !$html;
	print "  <tr>\n", if $html;
	printf("    <td>%-20s</td>\n    <td>%4d</td>    <td>%.2f", $key, $p{$key}{tp}, ($p{$key}{tp} / $p{$key}{total_rounds})), if $html;
	print "  </tr>\n", if $html;
    }
    print "\n", if !$html;
    print "</table></br>", if $html;

    print "<b>All Time Bogie Table:</b></br>\n", if $html;
    print "<head>\n<style>\n", if $html;
    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
    print "th, td {\n    text-align: left;\n}\n", if $html;
    print "</style>\n</head>\n", if $html;
    print "<table style=\"width:40\%\"></br>\n", if $html;
    print "  <tr>\n    <th>Name</th>\n    <th>Bogies</th>\n    <th>Bogies per 9-holes</th>\n  </tr>\n", if $html;
    print "All Time Bogie Table:\n", if !$html;
    foreach $key (sort { $p{$b}{bo} <=> $p{$a}{bo} } (keys(%p))) {
	if ($p{$key}{bo} == 0 || ($p{$key}{total_rounds} < 30)) {
	    next;
	}
	printf("%-17s: %d\t(%.2f bogies per 9 holes)\n", $key, $p{$key}{bo}, ($p{$key}{bo} / $p{$key}{total_rounds})), if !$html;
	print "  <tr>\n", if $html;
	printf("    <td>%-20s</td>\n    <td>%4d</td>    <td>%.2f", $key, $p{$key}{bo}, ($p{$key}{bo} / $p{$key}{total_rounds})), if $html;
	print "  </tr>\n", if $html;
    }
    print "\n", if !$html;
    print "</table></br>", if $html;

    print "<b>All Time Double Bogie Table:</b></br>\n", if $html;
    print "<head>\n<style>\n", if $html;
    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
    print "th, td {\n    text-align: left;\n}\n", if $html;
    print "</style>\n</head>\n", if $html;
    print "<table style=\"width:40\%\"></br>\n", if $html;
    print "  <tr>\n    <th>Name</th>\n    <th>Doubles</th>\n    <th>Doubles per 9-holes</th>\n  </tr>\n", if $html;
    print "All Time Double Bogie Table:\n", if !$html;
    foreach $key (sort { $p{$b}{tdb} <=> $p{$a}{tdb} } (keys(%p))) {
	if ($p{$key}{tdb} == 0 || ($p{$key}{total_rounds} < 30)) {
	    next;
	}
	printf("%-17s: %d\t(%.2f doubles per 9 holes)\n", $key, $p{$key}{tdb}, ($p{$key}{tdb} / $p{$key}{total_rounds})), if !$html;
	print "  <tr>\n", if $html;
	printf("    <td>%-20s</td>\n    <td>%4d</td>    <td>%.2f", $key, $p{$key}{tdb}, ($p{$key}{tdb} / $p{$key}{total_rounds})), if $html;
	print "  </tr>\n", if $html;
    }
    print "\n", if !$html;
    print "</table></br>", if $html;

    print "<b>All Time Others Table:</b></br>\n", if $html;
    print "<head>\n<style>\n", if $html;
    print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
    print "th, td {\n    text-align: left;\n}\n", if $html;
    print "</style>\n</head>\n", if $html;
    print "<table style=\"width:40\%\"></br>\n", if $html;
    print "  <tr>\n    <th>Name</th>\n    <th>Others</th>\n    <th>Others per 9-holes</th>\n  </tr>\n", if $html;
    print "All Time Others Table:\n", if !$html;
    foreach $key (sort { $p{$b}{to} <=> $p{$a}{to} } (keys(%p))) {
	if ($p{$key}{to} == 0 || ($p{$key}{total_rounds} < 30)) {
	    next;
	}
	printf("%-17s: %d\t(%.2f others per 9 holes)\n", $key, $p{$key}{to}, ($p{$key}{to} / $p{$key}{total_rounds})), if !$html;
	print "  <tr>\n", if $html;
	printf("    <td>%-20s</td>\n    <td>%4d</td>    <td>%.2f", $key, $p{$key}{to}, ($p{$key}{to} / $p{$key}{total_rounds})), if $html;
	print "  </tr>\n", if $html;
    }
    print "\n", if !$html;
    print "</table></br>", if $html;
}

sub print_stats {

    my($yp) = @_;

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


    if ($y{$yp}{total_strokes} && $stats) {
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

sub print_tables {

    my($yp) = @_;

    if (%{$bt{$yp}}) {
	%birds = %{$bt{$yp}};
	print "<b>Birdie Table: $yp</b></br>\n", if $html;
	print "<head>\n<style>\n", if $html;
	print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
	print "th, td {\n    text-align: left;\n}\n", if $html;
	print "</style>\n</head>\n", if $html;
	print "<table style=\"width:25\%\"></br>\n", if $html;
	print "  <tr>\n    <th>Name</th>\n    <th>Birdies</th>\n  </tr>\n", if $html;
	print "Birdie Table: $yp\n", if !$html;
	    foreach my $key (sort { $birds{$b} <=> $birds{$a} } keys %birds) {
		printf "%-20s %4d\n", $key, $birds{$key}, if !$html;
		print "  <tr>\n", if $html;
		printf "    <td>%-20s</td>\n    <td>%4d</td>", $key, $birds{$key}, if $html;
		print "  </tr>\n", if $html;
	    }
	print "</table></br>", if $html;
    }
    print "\n", if !$html;

    if (%{$et{$yp}}) {
	%eagles = %{$et{$yp}};
	print "<b>Eagle Table: $yp</b></br>\n", if $html;
	print "<head>\n<style>\n", if $html;
	print "table, th, td {\n    border: 1px solid black;\n    border-collapse: collapse;\n}\n", if $html;
	print "th, td {\n    text-align: left;\n}\n", if $html;
	print "</style>\n</head>\n", if $html;
	print "<table style=\"width:25\%\"></br>\n", if $html;
	print "  <tr>\n    <th>Name</th>\n    <th>Eagles</th>\n  </tr>\n", if $html;
	print "Eagle Table: $yp\n", if !$html;
	foreach my $key (sort { $eagles{$b} <=> $eagles{$a} } keys %eagles) {
	    printf "%-20s %4d\n", $key, $eagles{$key}, if !$html;
	    print "  <tr>\n", if $html;
	    printf "    <td>%-20s</td>\n    <td>%4d</td>", $key, $eagles{$key}, if $html;
	    print "  </tr>\n", if $html;
	}
	print "</table>\n", if $html;
    }
    print "\n", if !$html;
    print "</br>", if $html;
}

sub print_player_stats {

    foreach $x (sort keys %p) {

	$out_filename = "/tmp/$x";
	if ($output) {
	    open (PS, ">", $out_filename);
	    select PS;
	} elsif (-e $out_filename) {
	    unlink $out_filename;
	}

	my @courses = ("SF", "SB", "NF", "NB");

	#
	# Not all players play each year, so skip those that don't have posted scores.
	#
	if ($p{$x}{total_strokes} == 0) {
		next;
	}

	print "$x\n\n";
	print "$p{$x}{team}\n\n", if $debug;

        my $total_player_rounds = 0;
	while ($sc = shift @courses) {
	    if ($p{$x}{$sc}{xplayed} == 0) {
		next;
	    }
            printf("Played %-11s: %d times.\n", $c{$sc}->{name}, $p{$x}{$sc}{xplayed});
	    $total_player_rounds += $p{$x}{$sc}{xplayed};
	}
	print "\nTotal Strokes = $p{$x}{total_strokes}\n";
	printf("Total Average Score = %.2f\n", ($p{$x}{total_strokes} / $total_player_rounds));

	print "\n";

	@courses = ("SF", "SB", "NF", "NB");
	while ($sc = shift @courses) {

	    if ($p{$x}{$sc}{xplayed} == 0) {
		next;
	    }

	    print "$c{$sc}->{name}\n";

	    my $offset = 0;
	    if ($sc eq "NB" || $sc eq "SB") {
		$offset = 9;
	    }

	    for ($h = 1; $h < 10; $h++) {

		printf("Hole %d (par %d): Total shots: %3d  ", ($h + $offset), $c{$sc}->{$h}, $p{$x}{$sc}{$h}{shots});

		if ($c{$sc}->{$h} > 3) {
		    printf("ave=%.2f, %.2f vs. par, B: %d, E: %d\n", ($p{$x}{$sc}{$h}{shots} / $p{$x}{$sc}{xplayed}),
			(($p{$x}{$sc}{$h}{shots} / $p{$x}{$sc}{xplayed}) - $c{$sc}->{$h}),
			    $p{$x}{$sc}{$h}{b} ? $p{$x}{$sc}{$h}{b} : 0, $p{$x}{$sc}{$h}{e} ? $p{$x}{$sc}{$h}{e} : 0);
		} elsif ($c{$sc}->{$h} == 3) {
		    printf("ave=%.2f, %.2f vs. par, B: %d,", ($p{$x}{$sc}{$h}{shots} / $p{$x}{$sc}{xplayed}),
			(($p{$x}{$sc}{$h}{shots} / $p{$x}{$sc}{xplayed}) - $c{$sc}->{$h}),
			    $p{$x}{$sc}{$h}{b} ? $p{$x}{$sc}{$h}{b} : 0);
		    printf(" H: %d\n", $p{$x}{$sc}{$h}{e} ? $p{$x}{$sc}{$h}{e} : 0);
		}
		printf("\tPars=%d, Bogies=%d, Double Bogies=%d, Others=%d\n\n", $p{$x}{$sc}{$h}{p}, $p{$x}{$sc}{$h}{bo},
		    $p{$x}{$sc}{$h}{db}, $p{$x}{$sc}{$h}{o});
	    }
	    print "\n";
	}
        close(PS), if $output;
    }
}

sub get_player_trend {

    open(TD, "trend"), or die "Can't open file trend.\n";
    my (@ary);

    while (<TD>) {
	@ary = split(/:/, $_);
	$p{$ary[0]}{$ary[1]}{hc} = $ary[3];
    }
    close(TD);
}

sub get_player_scores {

    my($fn) = @_;

    open(FD, $fn);

    # Get the players name/team.
    $name = <FD>;
    chop($name);

    ($first, $last, $team) = split(/:/, $name);

    if ($team eq "Sub" && ($include_subs == 0)) {
	close (FD);
	return;
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

		$p{$pn}{total_rounds}++;
		$p{$pn}{total_strokes} += $shot;
		$p{$pn}{$course}{xplayed}++;
		$p{$pn}{$date}{score} = $shot;

		for ($h = 1; $h < 10; $h++) {
		    $hole = abs(shift @score);
		    $p{$pn}{$course}{$h}{shots} += $hole;
		    if (($c{$course}->{$h} - $hole) < -2) {
			$p{$pn}{to}++;
			$p{$pn}{$course}{$h}{o}++;
			$y{$start_year}{total_other}++;
		    };
		    if (($c{$course}->{$h} - $hole) == -2) {
			$p{$pn}{tdb}++;
			$p{$pn}{$course}{$h}{db}++;
			$y{$start_year}{total_db}++;
		    }
		    if (($c{$course}->{$h} - $hole) == -1) {
			$p{$pn}{bo}++;
			$p{$pn}{$course}{$h}{bo}++;
			$y{$start_year}{total_bogies}++;
		    }
		    if (($c{$course}->{$h} - $hole) == 0) {
			$p{$pn}{tp}++;
			$p{$pn}{$course}{$h}{p}++;
			$y{$start_year}{total_pars}++;
		    }
		    if (($c{$course}->{$h} - $hole) == 1) {
			$p{$pn}{$course}{$h}{b}++;
			$p{$pn}{tb}++;
			$y{$start_year}{total_birdies}++;
			$bt{$start_year}{$pn} += 1;
		    }
		    if (($c{$course}->{$h} - $hole) == 2) {
			$p{$pn}{$course}{$h}{e}++;
			$p{$pn}{te}++;
			$y{$start_year}{total_eagles}++;
			$et{$start_year}{$pn} += 1;
		    };
		}
	    }
	}
    }
    close(FD);
}
