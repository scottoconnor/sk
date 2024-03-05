#! /usr/bin/perl
#
# Copyright (c) 2018, 2024, Scott O'Connor
#

use strict;
require './tnfb_years.pl';
require './courses.pl';
require './subs.pl';
require './hcroutines.pl';

use Time::HiRes qw(gettimeofday);
use GDBM_File;
use Getopt::Long;

#
# Global variables.
#
my ($all_time) = 0;
my ($birdies_per_hole) = 0;
my ($birdies_per_player) = 0;
my ($cur_month) = (localtime)[4];
my ($cur_day) = (localtime)[3];
my ($start_year) = (1900 + (localtime)[5]);
my ($end_year) = $start_year;
my ($only_year) = 0;
my ($start_week) = 1;
my ($end_week) = 15;
my ($only_week) = 0;
my ($vhc) = 0;
my ($top_gun) = 0;
my ($stats) = 0;
my ($include_subs) = 0;
my ($player_stats) = 0;
my ($tables) = 0;
my ($output) = 0;
my ($html) = 0;
my ($others) = 0;
my ($hires) = 0;
my ($hardest) = 0;
my ($course_stats) = 0;
my ($most_improved) = 0;
my ($league) = "golfers";
my ($delete) = 0;
my ($add) = 0;
my ($perf) = 1;
my ($total_time) = 0;
my (undef(%totals));
my (undef(%y));
my (undef(%p));
my ($dh, %golfers_gdbm);
my (%tnfb_db);
my ($cy, $cw, $t0, $t1, $fna, $total_time);
my (%bt, %et, %difficult, %bph, %bpp, %to);

#
# These are hash variable from included files. see 'require' above.
#
our (%c);
our (%dates);
our (%subs);

if ($#ARGV < 0) {
    exit;
}

#
# If the league hasn't started this year, give stats from the previous year.
#
my ($year_day) = ((localtime)[7] + 1);
if ($year_day < 116) {
    $start_year = $end_year = ((1900 + (localtime)[5]) - 1);
}

GetOptions (
    "sy=i" => \$start_year,
    "ey=i" => \$end_year,
    "y=i" => \$only_year,
    "sw=i" => \$start_week,
    "ew=i" => \$end_week,
    "w=i" => \$only_week,
    "is" => \$include_subs,
    "vhc" => \$vhc,
    "at" => \$all_time,
    "c" => \$course_stats,
    "s" =>  \$stats,
    "p" =>  \$player_stats,
    "m" =>  \$most_improved,
    "t" =>  \$tables,
    "g" =>  \$top_gun,
    "l=s" => \$league,
    "o" => \$others,
    "ha" => \$hardest,
    "b" => \$birdies_per_hole,
    "bpp" => \$birdies_per_player,
    "r" => \$hires,
    "h" =>  \$html,
    "d" => \$delete,
    "a" => \$add)
or die("Error in command line arguments\n");

#
# If we are adding or deleting scores, we don't need to get data for stats.
#
if ($add || $delete) {
    $perf = 0;
}

if ($all_time || ($start_year < 1997)) {
    $start_year = 1997;
}

if ($all_time || $stats || $tables || $top_gun || $vhc || $others || $hardest ||
    $course_stats || $birdies_per_hole || $birdies_per_player) {
        $include_subs = 1;
}

if ($only_year) {
    $start_year = $end_year = $only_year;
}

if ($only_week) {
    $start_week = $end_week = $only_week;
}

#
# Open the league directory and only read the Gnu database files.
#
opendir($dh, "./$league") || die "Can't open \"$league\" directory.";

while (readdir $dh) {
    if ($_ =~ /(^1\d{3}$\.gdbm)/) {
        tie %tnfb_db, 'GDBM_File', "$league/$_", GDBM_READER, 0644
            or die "$GDBM_File::gdbm_errno";
        $golfers_gdbm{$tnfb_db{'Player'}} = "$league/$_";
        untie %tnfb_db;
    }
}
closedir ($dh);

#
# First get all the players scores/stats for the requested years/weeks.
# Calling get_player_scores will load up the hashes:
#         %p  with all the player data on a per player basis
#         %y  with all the yearly data on a per year basis
#
# After we get that, the other routines can use that data to generate stats.
#
for ($cy = $start_year; $cy <= $end_year && $perf; $cy++) {
    $t0 = gettimeofday(), if $hires;
    foreach my $pn (sort keys %golfers_gdbm) {
        my $file = $golfers_gdbm{$pn};
        get_player_scores($file, $pn, $cy);
    }
    $t1 = gettimeofday(), if $hires;
    $total_time += ($t1 - $t0), if $hires;
}

if ($most_improved) {
    show_most_improved();
}

#
# Delete a week of scores. The 'key' is the date of scores to delete.
#
if ($delete) {

    my ($count, $new_hi, $key);

    print "Enter date of scores to delete: ";
    chomp(my $key = <STDIN>);

    $count = 0;
    foreach my $pn (sort keys %golfers_gdbm) {
        my $file = $golfers_gdbm{$pn};
        tie %tnfb_db, 'GDBM_File', $file, GDBM_WRITER, 0640
            or die "$GDBM_File::gdbm_errno";

        if (defined($tnfb_db{$key})) {
            delete($tnfb_db{$key});
            $new_hi = gen_hi();
            $tnfb_db{'Current'} = $new_hi;
            $count++;
        }
        untie %tnfb_db;
    }
    print "$key: Deleted $count scores.\n";
}

#
# Add a week of scores.
#
if ($add) {

    my ($db_out, $course_rating, $slope, $gdbm_file, @sr, $pn, $new_hi);
    my ($date, $fn, @week, $month, $day, $year, $course, $line, $c, $fb);
    my ($hi, $ph, $post, $cph, $shot, @swings, $swing, $team);

    print "Enter week of play: ";
    chomp(my $w = <STDIN>);

    my @files = ("../golf/week$w-1.csv", "../golf/week$w-2.csv");

    foreach $fn (@files) {

        open(FD, $fn);

        while ($line = <FD>) {

            #
            # The first "if" gets the date, course information. Once we get this information
            # the next 4 matches (elsif) will be the scores for that time slot. This will
            # happen 4 times per sheet, 8 times for both sheets.
            #
            chomp($line);
            if ($line =~ /(4|5)\072\d{2}/) {
                @week = split (/,/, $line);
                $date = @week[0];
                ($year, $month, $day) = split /-/, $date;
                my $month = abs($month);
                my $day = abs($day);
                $date = "$year-$month-$day";
                #
                # Get the course and if it was front or back.
                #
                ($c, $fb) = $week[3] =~ /(S|N)\w+ (F|B)/;
                $course = "$c$fb";
                $course_rating = $c{$course}{course_rating};
                $slope = $c{$course}{slope};
            } elsif ($line =~ /^(\d{1,2})/) {
                @sr = split (/,/, $line);
                $pn = $sr[3];
                $cph = $sr[2];
                #
                # If the player doesn't exit, create their db file.
                #
                if (!exists($golfers_gdbm{$pn})) {
                    create_tnfb_db($pn);
                }
                $gdbm_file = $golfers_gdbm{$pn};
                $shot = abs(@sr[13]);
                @swings = @sr[4..12];
                ($hi, $ph, $post) = net_double_bogey($pn, $gdbm_file, $course, @swings);
                print "cph = $cph, ph = $ph\n", if ($cph != $ph);
                $db_out = "$course:$course_rating:$slope:$date:$hi:$ph:$shot:$post";
                while (my $swing = shift @swings) {
                    $db_out = $db_out . ":$swing";
                }
                tie %tnfb_db, 'GDBM_File', $gdbm_file, GDBM_WRITER, 0644
                    or die "$GDBM_File::gdbm_errno";
                        if (!defined($tnfb_db{$date})) {
                            $team = "Team_$year";
                            if ($year >= 2022 && !exists($tnfb_db{$team})) {
                                $tnfb_db{$team} = $tnfb_db{'Team'};
                                $tnfb_db{'Active'} = 1;
                            }
                            print "$pn $date: $db_out\n";
                            $tnfb_db{$date} = $db_out;
                            $new_hi = gen_hi();
                            $tnfb_db{'Current'} = $new_hi;
                        } else {
                            print "$pn: Score already exists.\n";
                        }
                untie %tnfb_db;
            }
        }
        close(FD);
    }
}

#
# Take the players round, calculate current course handicap and figure
# out their net double bogey for each hole.
#
sub
net_double_bogey {
    my ($pn, $file, $course, @s) = @_;
    my ($v, $hole, $post, $hi, $cd, $ch, $cch, $ph, $add_stroke);

    tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0644
        or die "$GDBM_File::gdbm_errno";

    $hi = $tnfb_db{'Current'};

    untie %tnfb_db;

    #
    # If the player does not have enough scores for a stable index,
    # input here what they player played at that night.
    #
    if ($hi == -100) {
        #
        # Enter the player's index determined before the round.
        #
        print "Enter index for $pn: ";
        $hi = <STDIN>;
        chomp $hi;
        print "$pn: using handicap index of -> $hi\n"
    }

    $cd = ($c{$course}{course_rating} - $c{$course}{par});
    $ch = (($hi * ($c{$course}->{slope} / 113)) + $cd);
    $cch = round($ch, 1);
    $ph = ($ch * 0.9);
    $ph = round($ph, 1);
    $ph = abs($ph), if ($ph == 0.0);

    $hole = 1; $post = 0;
    while (defined($v = shift(@s))) {
        $v = abs($v);

        #
        # Each player is allowed double bogey on each hole.  If the
        # hole is one of the player's handicap hole, they are allowed
        # one or more strokes.
        #
        my $max_score = ($c{$course}{$hole}[0] + 2);

        $add_stroke = ($cch - $c{$course}{$hole}[1]);
        if ($add_stroke >= 0 && $add_stroke < 9) {
            $max_score++;
        }
        if ($add_stroke >= 9) {
            $max_score += 2;
        }
        #if ($c{$course}{$hole}[1] <= $cch) { $max_score++ };

        $post += ($v > $max_score) ? $max_score : $v;
        $hole++;
    }
    return ($hi, $ph, $post);
}

sub
create_tnfb_db() {
    my ($new_pn) = @_;
    my ($new_file, $x, $y);

    for ($x = 1; $x < 300; $x++) {
        $y = 1000 + $x;
        $new_file = "golfers/" . $y . ".gdbm";
        if (! -e $new_file) {
            print "$new_pn new db file is: $new_file\n";
            $x = 1000;
        }
    }
    tie %tnfb_db, 'GDBM_File', $new_file, GDBM_WRCREAT, 0644
        or die "$GDBM_File::gdbm_errno";
    $tnfb_db{'Player'} = $new_pn;
    $tnfb_db{'Team'} = "Sub";
    $tnfb_db{'Active'} = 1;
    $tnfb_db{'Current'} = -100;
    untie %tnfb_db;

    #
    # Update golfers_gdbm hash
    #
    $golfers_gdbm{$new_pn} = $new_file;
}

#
# Print out the the players score verses their handicap on a weekly
# basis and average for the years specified.
#
if ($vhc) {

    my (%te, $tt);
    my $num_years = values(%y);

    foreach my $pn (sort keys %p) {
        if (($p{$pn}{total_strokes} == 0) || ($p{$pn}{total_rounds} == 0)) {
            next;
        }

        foreach my $yp (sort keys %y) {
            foreach my $w ($start_week..$end_week) {
                my $d = $dates{$yp}{$w};
                if ($p{$pn}{$d}{shot} && defined($p{$pn}{$d}{hc})) {

                    #
                    # Do not count weeks we don't have a valid
                    # handicap index or handicap.
                    #
                    if ($p{$pn}{$d}{hc} eq "NA") {
                        next;
                    }

                    $p{$pn}{diff} += $p{$pn}{$d}{diff};
                    printf("%-17s: year %-4d week %-2s shot %d, hc %2d, net %d, diff %d\n", $pn, $yp, $w,
                        $p{$pn}{$d}{shot}, $p{$pn}{$d}{hc}, $p{$pn}{$d}{net}, $p{$pn}{$d}{diff});
                }
            }
        }
        $p{$pn}{avediff} = ($p{$pn}{diff} / $p{$pn}{total_rounds}), if ($p{$pn}{total_rounds} > 0);
        $te{$p{$pn}{team}} += $p{$pn}{avediff};
        print "\n", if ($p{$pn}{total_rounds} > 0);
    }

    foreach my $pn (sort { $p{$a}{avediff} <=> $p{$b}{avediff} } (keys(%p))) {
        if ($p{$pn}{total_rounds} == 0 ||
            (($p{$pn}{team} eq "Sub") && ($include_subs == 0))) {
                next;
        }
        printf("%-25s %-17s: Ave = %.2f \(total rounds %d\)\n", $p{$pn}{team},
            $pn, $p{$pn}{avediff}, $p{$pn}{total_rounds});
    }

    print "\n";
    foreach $tt (sort { $te{$a} <=> $te{$b} } (keys (%te))) {
        if ($tt eq "Sub") {
            next;
        }
        printf("%-25s: %.2f\n", $tt, ($te{$tt}/$num_years));
    }
}

#
# Now print out the data for those years/weeks.
#
# The years are printed in descending order.
#
foreach my $yp (reverse sort keys %y) {
    if ($stats) {
        print_stats($yp);
    }
    if ($tables) {
        print_tables($yp);
    }
}

if ($top_gun) {

    my (%thirty, %ty);

    #
    # First check to see if anyone shot in the 30's, if not just exit.
    #
    foreach my $pn (keys %p) {
        foreach my $yp (sort keys %y) {
            foreach my $w ($start_week..$end_week) {
                if ($p{$pn}{$yp}{$w} != 0 && $p{$pn}{$yp}{$w} < 40) {
                    $thirty{$yp}{$w}{$pn} = $p{$pn}{$yp}{$w};
                }
            }
        }
    }

    if (keys %thirty == 0) {
        exit;
    }

    print "30's Club:\n", if !$html;
    print "<b>30's Club:</b>", if $html;
    print "\n<head>\n", if $html;
    print "<style>\n", if $html;
    print " table {\n  border-collapse: collapse;\n }\n", if $html;
    print " table, td, th {\n  border: 1px solid black;\n }\n", if $html;
    print "</style>\n", if $html;
    print "</head>\n", if $html;
    print "<table border=\"1\" width = \"300\">\n", if $html;
    print "  <tr>\n    <th style=\"text-align:left\">Name</th>\n", if $html;
    print "    <th style=\"text-align:center\">Score</th>\n  </tr>\n", if $html;

    foreach my $yp (sort keys %y) {
        foreach my $w ($start_week..$end_week) {
            %ty = %{$thirty{$yp}{$w}};
            my $has_rounds = 0;
            foreach my $pn (sort { $ty{$a} <=> $ty{$b} } keys %ty) {
                print "  <tr>\n", if $html;
                printf("    <td>%s</td>\n", $pn), if $html;
                printf("    <td style=\"text-align:center\">%d</td>\n", $ty{$pn}), if $html;
                print "  </tr>\n", if $html;
                printf("%-17s: shot %d (week %d, year %d)\n", $pn, $ty{$pn}, $w, $yp), if !$html;
                $has_rounds = 1;
            }
            print "\n", if (!$html && ($start_week != $end_week) && ($has_rounds));
        }
    }
    print "</table></br>\n", if $html;
}

if ($others) {
    my ($par, $score);

    for ($par = 3; $par < 6; $par++) {
        print "On par $par\'s:\n";
        for ($score = 6; $score < 15; $score++) {
            if (!defined($to{$par}{$score})) {
                next;
            }
            if ($to{$par}{$score} == 1) {
                print "    The score of $score was shot $to{$par}{$score} time.\n";
            } else {
                print "    The score of $score was shot $to{$par}{$score} times.\n";
            }
        }
        print "\n";
    }
}

#
# Print out player's hole-by-hole stats if requested.
#
if ($player_stats) {
    print_player_stats();
}

if ($all_time) {
    my ($key);

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

sub
print_stats {

    my($yp) = @_;

    if ($y{$yp}{total_strokes} && !$html) {
        print "$yp";
        print " - Weeks $start_week through $end_week",
            if (($end_week - $start_week) < 14) && (($end_week - $start_week) > 0);
        print " - Week $start_week", if ($start_week == $end_week);
        print ":\n";

        printf("Total Posted scores: %d\n", $y{$yp}{total_scores});
        printf("Total holes played: %d\n", ($y{$yp}{total_scores} * 9));
        printf("Total Strokes = %d\n", $y{$yp}{total_strokes});
        printf("League Stroke Average = %.2f\n",
            ($y{$yp}{total_strokes} / $y{$yp}{total_scores}));
        printf("Total Eagles = %d\n", $y{$yp}{total_eagles});
        printf("Total Birdies = %d\n", $y{$yp}{total_birdies});
        printf("Total Pars = %d\n", $y{$yp}{total_pars});
        printf("Total Bogies = %d\n", $y{$yp}{total_bogies});
        printf("Total Double Bogies = %d\n", $y{$yp}{total_db});
        printf("Total Others = %d\n", $y{$yp}{total_other});
        printf("Total 30's = %d\n", $y{$yp}{thirties});
        printf("Total 50+ = %d\n\n", $y{$yp}{fifty_plus});

    } elsif ($y{$yp}{total_strokes} && $html) {
        print "<b><font color=\"green\">$yp</font></b>";
        print "<b><font color=\"green\"> - Weeks $start_week through $end_week</font></b>\n",
            if (($end_week - $start_week) < 14) && (($end_week - $start_week) > 0);
        print "<b><font color=\"green\"> - Week $start_week</font></b>", if ($start_week == $end_week);
        print "<b><font color=\"green\">:</font></b></br>\n";

        printf("Total Posted scores: <b><font color=\"green\">%d</font></b></br>\n", $y{$yp}{total_scores});
        printf("Total holes played: <b><font color=\"green\">%d</font></b></br>\n", ($y{$yp}{total_scores} * 9));
        printf("Total Strokes = <b><font color=\"green\">%d</font></b></br>\n", $y{$yp}{total_strokes});
        printf("League Stroke Average = <b><font color=\"green\">%.2f</font></b></br>\n",
            ($y{$yp}{total_strokes} / $y{$yp}{total_scores}));
        printf("Total Eagles  = <b><font color=\"green\">%d</font></b></br>\n", $y{$yp}{total_eagles});
        printf("Total Birdies = <b><font color=\"green\">%d</font></b></br>\n", $y{$yp}{total_birdies});
        printf("Total Pars = <b><font color=\"green\">%d</font></b></br>\n", $y{$yp}{total_pars});
        printf("Total Bogies = <b><font color=\"green\">%d</font></b></br>\n", $y{$yp}{total_bogies});
        printf("Total Double Bogies = <b><font color=\"green\">%d</font></b></br>\n", $y{$yp}{total_db});
        printf("Total Others = <b><font color=\"green\">%d</font></b></br></br>\n", $y{$yp}{total_other});
    }
}

if ($course_stats) {

    my @courses = ("SF", "SB", "NF", "NB");
    while (my $sc = shift @courses) {
        if ($c{$sc}{total_strokes} == 0) {
            next;
        }
        $c{$sc}{ave_score} = ($c{$sc}{total_strokes} / $c{$sc}{total_scores});
    }
    foreach my $key (reverse sort { $c{$b}{ave_score} <=> $c{$a}{ave_score} } keys %c) {
        if ($c{$key}{total_strokes} == 0) {
            next;
        }
        printf("%-11s: Stroke Average = %.2f\n", $c{$key}->{name}, ($c{$key}{ave_score}));
    }
}

sub
print_tables {

    my($yp) = @_;
    my(%birds, %eagles, $size);

    if ($bt{$yp}) {
        %birds = %{$bt{$yp}};
        print "Birdie Table $yp", if !$html;
        print " - Weeks $start_week through $end_week",
            if ((($end_week - $start_week) < 14) && ($end_week - $start_week) > 0) && !$html;
        print " - Week $start_week", if ($start_week == $end_week) && !$html;
        print ":\n", if !$html;
        print "<b>Birdie Table $yp</b>", if $html;
        print "<b> - Weeks $start_week through $end_week:</b>",
            if ((($end_week - $start_week) < 14) && ($end_week - $start_week) > 0) && $html;
        print "<b> - Week $start_week:</b>", if ($start_week == $end_week) && $html;
        print "\n<head>\n", if $html;
        print "<style>\n", if $html;
        print " table {\n  border-collapse: collapse;\n }\n", if $html;
        print " table, td, th {\n  border: 1px solid black;\n }\n", if $html;
        print "</style>\n", if $html;
        print "</head>\n", if $html;
        #print "<table style=\"width:25\%\"></br>\n", if $html;
        print "<table border=\"1\" width = \"300\">\n", if $html;
        print "  <tr>\n    <th style=\"text-align:left\">Name</th>\n", if $html;
        print "    <th style=\"text-align:center\">Birdies</th>\n  </tr>\n", if $html;

        foreach my $key (sort { $birds{$b} <=> $birds{$a} } keys %birds) {
            printf "%-20s %4d\n", $key, $birds{$key}, if !$html;
            print "  <tr>\n", if $html;
            printf "    <td>%s</td>\n    <td style=\"text-align:center\">%d</td>\n", $key, $birds{$key}, if $html;
            print "  </tr>\n", if $html;
        }
        print "</table></br>\n", if $html;
        print "\n", if !$html;
    }

    if ($et{$yp}) {
        %eagles = %{$et{$yp}};
        print "Eagle Table $yp", if !$html;
        print " - Weeks $start_week through $end_week",
            if ((($end_week - $start_week) < 14) && ($end_week - $start_week) > 0) && !$html;
        print " - Week $start_week", if ($start_week == $end_week) && !$html;
        print ":\n", if !$html;
        print "<b>Eagle Table $yp</b>\n", if $html;
        print "<b> - Weeks $start_week through $end_week:</b>",
            if ((($end_week - $start_week) < 14) && ($end_week - $start_week) > 0) && $html;
        print "<b> - Week $start_week:</b>", if ($start_week == $end_week) && $html;
        print "\n<head>\n", if $html;
        print "<style>\n", if $html;
        print " table {\n  border-collapse: collapse;\n }\n", if $html;
        print " table, td, th {\n  border: 1px solid black;\n }\n", if $html;
        print "</style>\n", if $html;
        print "</head>\n", if $html;
        #print "<table style=\"width:25\%\"></br>\n", if $html;
        print "<table border=\"1\" width = \"300\">\n", if $html;
        print "  <tr>\n    <th style=\"text-align:left\">Name</th>\n", if $html;
        print "    <th style=\"text-align:center\">Eagles</th>\n  </tr>\n", if $html;
        foreach my $key (sort { $eagles{$b} <=> $eagles{$a} } keys %eagles) {
            printf "%-20s %4d\n", $key, $eagles{$key}, if !$html;
            print "  <tr>\n", if $html;
            printf "    <td>%s</td>\n    <td style=\"text-align:center\">%d</td>", $key, $eagles{$key}, if $html;
            print "  </tr>\n", if $html;
        }
        print "</table></br>\n", if $html;
        print "\n", if !$html;
    }
}

sub
print_player_stats {

    foreach my $pn (sort keys %p) {

        my $out_filename = "/tmp/$pn", if ($output);
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
        if ($p{$pn}{total_strokes} == 0) {
            next;
        }

        print "$pn\n\n";

        my $total_player_rounds = 0;
        while (my $sc = shift @courses) {
            if ($p{$pn}{$sc}{xplayed} == 0) {
                next;
            }
            printf("Played %-11s: %d times.\n", $c{$sc}->{name}, $p{$pn}{$sc}{xplayed});
            $total_player_rounds += $p{$pn}{$sc}{xplayed};
        }
        print "\nTotal Strokes = $p{$pn}{total_strokes}\n";
        printf("Average Score = %.2f\n", ($p{$pn}{total_strokes} / $total_player_rounds));
        printf("Total Eagles = %d\n", $p{$pn}{te});
        printf("Total Birdies = %d\n", $p{$pn}{tb});

        print "\n";

        @courses = ("SF", "SB", "NF", "NB");
        while (my $sc = shift @courses) {

            if ($p{$pn}{$sc}{xplayed} == 0) {
                next;
            }

            print "$c{$sc}->{name}\n";

            my $offset = 0;
            if ($sc eq "NB" || $sc eq "SB") {
                $offset = 9;
            }

            for (my $h = 1; $h < 10; $h++) {

                printf("Hole %d (par %d): Total shots: %3d  ", ($h + $offset), $c{$sc}{$h}[0], $p{$pn}{$sc}{$h}[0]{shots});

                if ($c{$sc}{$h}[0] > 3) {
                    printf("ave = %.2f\n  Eagles=%d, ", ($p{$pn}{$sc}{$h}[0]{shots} / $p{$pn}{$sc}{xplayed}),
                        $p{$pn}{$sc}{$h}[0]{e} ? $p{$pn}{$sc}{$h}[0]{e} : 0);
                } elsif ($c{$sc}{$h}[0] == 3) {
                    printf("ave = %.2f\n  Hole-in-Ones=%d, ", ($p{$pn}{$sc}{$h}[0]{shots} / $p{$pn}{$sc}{xplayed}),
                        $p{$pn}{$sc}{$h}[0]{e} ? $p{$pn}{$sc}{$h}[0]{e} : 0);
                }
                printf("Birdies=%d, Pars=%d, Bogies=%d, Double Bogies=%d, Others=%d\n\n", $p{$pn}{$sc}{$h}[0]{b},
                    $p{$pn}{$sc}{$h}[0]{p}, $p{$pn}{$sc}{$h}[0]{bo}, $p{$pn}{$sc}{$h}[0]{db}, $p{$pn}{$sc}{$h}[0]{o});
            }
            print "\n";
        }
        close(PS), if $output;
    }
}

if ($hardest) {
    my ($course, $index, $ph, $hp, $offset);

    foreach $hp (keys %difficult) {
        $difficult{$hp}{ave} = ($difficult{$hp}{score} / $difficult{$hp}{xplayed});
        $offset = 0;
        if ($hp > 0 && $hp < 10) {
            $course = 'SF';
            $index = $hp;
        } elsif ($hp > 9 && $hp < 19) {
            $course = 'SB';
            $index = ($hp - 9);
        } elsif ($hp > 18 && $hp < 28) {
            $course = 'NF';
            $offset = 18;
            $index = ($hp - 18);
        } else {
            $course = 'NB';
            $offset = 18;
            $index = ($hp - 27);
        }
        $ph = ($hp - $offset);
        $difficult{$hp}{ave} -= $c{$course}->{$index}[0];
    }

    foreach $hp (reverse sort { $difficult{$a}{ave} <=> $difficult{$b}{ave} } (keys(%difficult))) {
        $offset = 0;
        if ($hp > 0 && $hp < 10) {
            $course = 'SF';
            $index = $hp;
        } elsif ($hp > 9 && $hp < 19) {
            $course = 'SB';
            $index = ($hp - 9);
        } elsif ($hp > 18 && $hp < 28) {
            $course = 'NF';
            $offset = 18;
            $index = ($hp - 18);
        } else {
            $course = 'NB';
            $offset = 18;
            $index = ($hp - 27);
        }
        $ph = ($hp - $offset);
        printf("%-11s hole %2d (par %d) average over par = %.2f (played %d times)\n", $c{$course}->{name}, $ph,
            $c{$course}->{$index}[0], $difficult{$hp}{ave}, $difficult{$hp}{xplayed});
    }
}

if ($birdies_per_hole) {
    my ($course, $offset, $ph);

    foreach my $hp (reverse sort { $bph{$a}{b} <=> $bph{$b}{b} } (keys(%bph))) {

        $offset = 0;

        if ($hp > 0 && $hp < 10) {
            $course = 'South Front';
            #$index = $hp;
        } elsif ($hp > 9 && $hp < 19) {
            $course = 'South Back';
            #$index = ($hp - 9);
        } elsif ($hp > 18 && $hp < 28) {
            $course = 'North Front';
            $offset = 18;
            #$index = ($hp - 18);
        } else {
            $course = 'North Back';
            $offset = 18;
            #$index = ($hp - 27);
        }
        $ph = ($hp - $offset);

        print "$course, hole $ph - total birdies -> $bph{$hp}{b}\n";
    }
}

printf("Total time = %.2f seconds - processed %d scores\n", $total_time, $totals{total_scores}), if $hires;

sub
show_most_improved {

    my ($cw, $mi, $d, %p, @score, %mi);

    foreach my $pn (sort keys %golfers_gdbm) {
        my $file = $golfers_gdbm{$pn};

        tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0640
            or die "$GDBM_File::gdbm_errno";

        #
        # If start year is the same as end year, include players
        # that played that year. Should always find 32 players.
        #
        # If we are looking at multiple years,  only include
        # players that are current TNFB members.
        #
        if ($start_year == $end_year) {
            if ($tnfb_db{"Team_$start_year"} eq "Sub") {
                untie %tnfb_db;
                next;
            }
        } else {
            if ($tnfb_db{'Team'} eq "Sub") {
                untie %tnfb_db;
                next;
            }
        }


        #
        # Get 'A' index from the first score posted in the start_year.
        #
        for ($cw = $start_week; $cw <= $end_week; $cw++) {
            $d = $dates{$start_year}{$cw};
            if (!defined($p{$pn}{A}) && exists($tnfb_db{$d})) {
                @score = split(/:/, $tnfb_db{$d});
                if (@score[4] ne "NA") {
                    $p{$pn}{A} = (@score[4] + 6);
                    $p{$pn}{Adate} = $d;
                    last;
                }
            }
        }

        #
        # Now get 'B' index from (end_year + 1) first posted score.
        #
        for ($cw = 1; $cw <= $end_week; $cw++) {
            $d = $dates{($end_year+1)}{$cw};
            if (!defined($p{$pn}{B}) && exists($tnfb_db{$d})) {
                @score = split(/:/, $tnfb_db{$d});
                if (@score[4] ne "NA") {
                    $p{$pn}{B} = (@score[4] + 6);
                    $p{$pn}{Bdate} = $d;
                }
            }
        }

        #
        # If we haven't found 'B' yet, grab the current index.
        #
        if (!defined($p{$pn}{B})) {
            $p{$pn}{B} = ($tnfb_db{'Current'} + 6);
            $p{$pn}{Bdate} = "Current";
        }

        if (defined($p{$pn}{A}) && defined($p{$pn}{B})) {
            print "$pn: A: $p{$pn}{Adate} $p{$pn}{A} ",
                "B: $p{$pn}{Bdate} $p{$pn}{B}\n", if 0;
        }

        untie %tnfb_db;
    }

    foreach my $pn (keys %p) {
        if (defined($p{$pn}{A}) && defined($p{$pn}{B})) {
            $mi{$pn}{mi} = ($p{$pn}{A} / $p{$pn}{B});
            $mi{$pn}{mi} = round($mi{$pn}{mi}, 1000);
        }
    }
    foreach my $pn (reverse sort { $mi{$a}{mi} <=> $mi{$b}{mi} } (keys(%mi))) {
        printf("%-17s %.3f\n", $pn, $mi{$pn}{mi});
    }
}

if ($birdies_per_player) {
    foreach my $cc (reverse sort keys %bpp) {
        my %holes = %{$bpp{$cc}};
        foreach my $hn (sort keys(%holes)) {
            print "$c{$cc}{name}: \#$hn\n";
            print "-----------\n";
            my %players = %{$bpp{$cc}{$hn}};
            foreach my $pn (reverse sort { $players{$a} <=> $players{$b} } (keys(%players))) {
                print "$pn: $players{$pn}\n";
            }
            print "\n\n";
        }
    }
}

sub
get_player_scores {

    my($fn, $pn, $cy) = @_;

    my($cw, $date, $h, $hi, $hc, %tnfb_db);
    my($course, $par, $slope, $date, $hi, $hc, $shot, $post, $md);

    tie %tnfb_db, 'GDBM_File', $fn, GDBM_READER, 0640
        or die "$GDBM_File::gdbm_errno";

    for ($cw = $start_week; $cw <= $end_week; $cw++) {

        my $d = $dates{$cy}{$cw};

        #
        # If no score on this week, push on.
        #
        if (!exists($tnfb_db{$d})) {
            next;
        }

        my @score_record = split(/:/, $tnfb_db{$d});

        #
        # Only provide stats with hole-by-hole data.
        #
        if (scalar(@score_record) < 17) {
            untie %tnfb_db;
            die "Bogus score for $pn on $d\n";
        }

        #
        # Get the team the player played on this year.
        #
        $p{$pn}{team} = $tnfb_db{"Team_$cy"};
        print "$pn was a $p{$pn}{team} in $cy week $cw\n", if 0;

        #
        # If the player is a subs, find who they were subbing for.
        #
        if ($p{$pn}{team} eq "Sub") {
            if (!defined($subs{$cy}{$cw}{$pn})) {
                untie %tnfb_db;
                die "$pn is not a valid sub?\n";
            }
            my $league_fn = $golfers_gdbm{$subs{$cy}{$cw}{$pn}};

            tie my %sub_db, 'GDBM_File', $league_fn, GDBM_READER, 0640
                or die "$GDBM_File::gdbm_errno";

            $p{$pn}{team} = $sub_db{"Team_$cy"};

            untie %sub_db;
            print "$pn Subbed for $subs{$cy}{$cw}{$pn} ($p{$pn}{team}) in $cy week $cw\n", if 0;
        }

        #
        # Set the player's team for this date (year/week).
        # Currently not used.
        #
        $p{$pn}{$d}{team} = $p{$pn}{team};

        ($course, $par, $slope, $date, $hi, $hc, $shot, $post) = @score_record[0..7];
        my @score = @score_record[8..16];

        if (defined($p{$pn}{$cy}{$cw})) {
            print "Possible double score: $pn: Week=$cw, Date=$d\n";
            next;
        }

        $y{$cy}{total_strokes} += $shot;
        $y{$cy}{total_scores}++;
        $totals{total_scores}++;
        $c{$course}{total_strokes} += $shot;
        $c{$course}{total_scores}++;

        $p{$pn}{total_rounds}++;
        $p{$pn}{total_strokes} += $shot;
        $p{$pn}{$course}{xplayed}++;
        $p{$pn}{$cy}{$cw} = $shot;
        $p{$pn}{$d}{shot} = $shot;
        $p{$pn}{$d}{hc} = $hc;
        $p{$pn}{$d}{hi} = $hi;
        $p{$pn}{$d}{net} = ($shot - $hc);
        $p{$pn}{$d}{diff} = (($shot - $hc) - 36);
        if ($shot >= 50) {
            $y{$cy}{fifty_plus}++;
        }
        if ($shot < 40) {
            $y{$cy}{thirties}++;
        }

        for ($h = 1; $h < 10; $h++) {
            my $hole = abs(shift @score);

            my $bh = $h;
            if (($course eq 'SB') || ($course eq 'NB')) {
                $bh += 9;
            }

            $md = ($h + (($course eq 'SF') ? 0 : ($course eq 'SB') ? 9 :
                ($course eq 'NF') ? 18 : ($course eq 'NB') ? 27 : 0)), if ($hardest || $birdies_per_hole);
            $difficult{$md}{score} += $hole, if $hardest;
            $difficult{$md}{xplayed}++, if $hardest;

            $p{$pn}{$course}{$h}[0]{shots} += $hole;

            if (($c{$course}{$h}[0] - $hole) < -2) {
                $p{$pn}{to}++;
                $p{$pn}{$course}{$h}[0]{o}++;
                $y{$cy}{total_other}++;
                $to{$c{$course}{$h}[0]}{$hole}++;
            };
            if (($c{$course}{$h}[0] - $hole) == -2) {
                $p{$pn}{tdb}++;
                $p{$pn}{$course}{$h}[0]{db}++;
                $y{$cy}{total_db}++;
            }
            if (($c{$course}{$h}[0] - $hole) == -1) {
                $p{$pn}{bo}++;
                $p{$pn}{$course}{$h}[0]{bo}++;
                $y{$cy}{total_bogies}++;
            }
            if (($c{$course}{$h}[0] - $hole) == 0) {
                $p{$pn}{tp}++;
                $p{$pn}{$course}{$h}[0]{p}++;
                $y{$cy}{total_pars}++;
            }
            if (($c{$course}{$h}[0] - $hole) == 1) {
                $p{$pn}{$course}{$h}[0]{b}++;
                $p{$pn}{tb}++;
                $y{$cy}{total_birdies}++;
                $bt{$cy}{$pn} += 1;
                $bph{$md}{b}++;
                $bpp{$course}{$bh}{$pn}++;
            }
            if (($c{$course}{$h}[0] - $hole) == 2) {
                $p{$pn}{$course}{$h}[0]{e}++;
                $p{$pn}{te}++;
                $y{$cy}{total_eagles}++;
                $et{$cy}{$pn} += 1;
            }
        }
    }
    untie %tnfb_db;
}
