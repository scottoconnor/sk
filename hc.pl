#! /usr/bin/perl
#
# Copyright (c) 2018, 2026 Scott O'Connor
#

use strict;
require './tnfb_years.pl';
require './hcroutines.pl';

use Getopt::Long;
use GDBM_File;

my ($allowance) = 0.9;
my ($expected_diff) = 0;
my (undef($name));
my (%tnfb_db, %league, $dh);
my ($max_scores) = 20;
my ($sf, $sb, $nf, $nb);
our (%dates);
my ($league) = "./golfers";
my (%golfers_gdbm);
my ($total_scores, $div, %t, $tier, $course_data, @course_elements);
my ($end_year) = (1900 + (localtime)[5]);
my ($year) = $end_year;
my @courses = ("SF", "SB", "NF", "NB");

$div = 5;

GetOptions (
    "x" => \$expected_diff,
    "n=s" => \$name,
    "a=f" => \$allowance),
or die("Error in command line arguments\n");

my ($month) = (localtime)[4];
$month++;
my ($day) = (localtime)[3];

opendir($dh, "$league") || die "Can't open \"$league\" directory.";

#
# Read and store the Gnu gdbm database files.
#
while (readdir $dh) {
    if ($_ =~ /(^1\d{3}$\.gdbm)/) {
        tie %tnfb_db, 'GDBM_File', "$league/$_", GDBM_READER, 0644
            or die "$GDBM_File::gdbm_errno";
        $golfers_gdbm{$tnfb_db{'Player'}} = "$league/$_";
        untie %tnfb_db;
    }
}
closedir ($dh);

foreach my $pn (keys %golfers_gdbm) {

    my $file = $golfers_gdbm{$pn};
    my ($course_year);

    tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0644
        or die "$GDBM_File::gdbm_errno";

    foreach my $y (2003..$end_year) {
        foreach my $m (4..9) {
            foreach my $d (1..31) {
                my $date = "$y-$m-$d";
                if (exists($tnfb_db{$date})) {
                    my @sr = split(/:/, $tnfb_db{$date});
                    print "$date: $tnfb_db{$date}\n", if 0;
                    print "$date: @sr\n", if 0;
                    print "$date: $sr[4], $sr[6]\n", if 0;

                    ($course_year) = $sr[3] =~ /(\d\d\d\d)-/;
                    print "year = $course_year\n", if (0);
                    $course_data = get_course_data($course_year, $sr[0]);
                    print "course data $course_data\n", if (0);
                    @course_elements = split(/:/, $course_data);

                    $tier = int($sr[4] / $div);
                    print "tier $tier: hi = $sr[4]\n", if 0;
                    $t{$tier}{strokes} += $sr[4];
                    $t{$tier}{xplayed}++;
                    $t{$tier}{scores}++;
                    $t{$sr[0]}{$tier}{strokes} += $sr[4];
                    $t{$sr[0]}{$tier}{xplayed}++;
                    $t{$sr[0]}{$tier}{scores}++;

                    $total_scores++;
                }
            }
        }
    }
}

while (my $sc = shift @courses) {
    for ($tier = 0; $tier < 8; $tier++) {
        if (!defined($t{$sc}{$tier})) {
            next;
        }
        my $ave = (($t{$sc}{$tier}{strokes}/$t{$sc}{$tier}{xplayed}) * 1.0);
        $t{$sc}{$tier}{ave} = $ave;
        printf("%s: tier %d, (scores %d), strokes %d, ave = %.2f\n", $sc, $tier,
            $t{$sc}{$tier}{scores}, $t{$sc}{$tier}{strokes}, $ave), if (0);

    }
}

foreach my $pn (keys %golfers_gdbm) {

    my $file = $golfers_gdbm{$pn};

    tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0644
        or die "$GDBM_File::gdbm_errno";

    #
    # Only add a player to the handicap list if they are active
    # and have a valid handicap index.
    #
    if ($tnfb_db{'Active'} == 0 || $tnfb_db{'Current'} == -100) {
        untie %tnfb_db;
        next;
    }

    (my $first, my $last) = split(/ /, $tnfb_db{'Player'}, 2);
    my $pn = "$last, $first";

    $league{$tnfb_db{'Team'}}{$pn}{hi} = $tnfb_db{'Current'};

    untie %tnfb_db;

    if ($expected_diff) {
        expected_diff($file);
    }
}
closedir ($dh);

print "$month-$day-$year               (sf sb nf nb)\n", if !defined($name);

#
# First, print out the league members.
#
foreach my $team (sort keys(%league)) {
    if ($team eq "Sub") {
        next;
    }
    print "$team\n", if !defined($name);
    my %tnfb = %{$league{$team}};
    foreach my $pn (sort keys %tnfb) {
        ($sf, $sb, $nf, $nb) = gen_handicap($tnfb{$pn}{hi});
        printf("%-18s %4.1fN /%2d %2d %2d %2d\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb), if !defined($name);
    }
    print "\n", if !defined($name);
}

#
# Now print out the subs.
#
foreach my $team (sort keys(%league)) {
    if ($team ne "Sub") {
        next;
    }
    print "$team\n", if !defined($name);
    my %tnfb = %{$league{$team}};
    foreach my $pn (sort keys %tnfb) {
        ($sf, $sb, $nf, $nb) = gen_handicap($tnfb{$pn}{hi});
        printf("%-18s %4.1fN /%2d %2d %2d %2d%s\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb), if !defined($name);
    }
}

sub
gen_handicap {
    my ($hi) = @_;
    my ($course_data, @course_elements, $course_rating, $slope, $par);

    $course_data = get_course_data($year, "SF");
    print "course data $course_data\n", if (0);
    @course_elements = split(/:/, $course_data);
    ($course_rating, $slope) = @course_elements[1..2];
    $par = $course_elements[3];
    print "SF: $course_rating, $slope\n", if (0);

    my $sfd = ($course_rating - $par);
    my $sf = (($hi * ($slope / 113)) + $sfd);
    $sf *= $allowance;
    $sf = round($sf, 1);

    $course_data = get_course_data($year, "SB");
    print "course data $course_data\n", if (0);
    @course_elements = split(/:/, $course_data);
    ($course_rating, $slope) = @course_elements[1..2];
    $par = $course_elements[3];
    print "SB: $course_rating, $slope\n", if (0);

    my $sbd = ($course_rating - $par);
    my $sb = (($hi * ($slope / 113)) + $sbd);
    $sb *= $allowance;
    $sb = round($sb, 1);

    $course_data = get_course_data($year, "NF");
    print "course data $course_data\n", if (0);
    @course_elements = split(/:/, $course_data);
    ($course_rating, $slope) = @course_elements[1..2];
    $par = $course_elements[3];
    print "NF: $course_rating, $slope\n", if (0);

    my $nfd = ($course_rating - $par);
    my $nf = (($hi * ($slope / 113)) + $nfd);
    $nf *= $allowance;
    $nf = round($nf, 1);

    $course_data = get_course_data($year, "NB");
    print "course data $course_data\n", if (0);
    @course_elements = split(/:/, $course_data);
    ($course_rating, $slope) = @course_elements[1..2];
    $par = $course_elements[3];
    print "NB: $course_rating, $slope\n", if (0);

    my $nbd = ($course_rating - $par);
    my $nb = (($hi * ($slope / 113)) + $nbd);
    $nb *= $allowance;
    $nb = round($nb, 1);

    return ($sf, $sb, $nf, $nb);
}

sub
expected_diff {
    my ($fn) = @_;

    my (%tnfb_db, $use, @sr, $diff, %pc, $hi, %pd, $by, $id, $nd);

    tie %tnfb_db, 'GDBM_File', $fn, GDBM_WRITER, 0644
        or die "$GDBM_File::gdbm_errno";

    my ($first, $last) = split(/ /, $tnfb_db{'Player'}, 2);

    my $pn = "$last, $first";
    my $team = $tnfb_db{'Team'};
    my $hi = $tnfb_db{'Current'};

    undef(my @scores);
    my $num_scores = 0;
    $by = ($year - 5);

    print "$by to $year\n", if (0);

    foreach my $y (reverse ($by..$year)) {
        foreach my $w (reverse (1..15)) {
            if (exists($tnfb_db{$dates{$y}{$w}})) {
                @sr = split(/:/, $tnfb_db{$dates{$y}{$w}});
                print "$sr[0]: Scoring Record: @sr\n", if (0);
                $diff = ((113 / $sr[2]) * ($sr[7] - $sr[1]));
                my $tier = int($sr[4] / $div);
                #printf("%s: score diff: %.2f, xd = %.2f\n", $pn, $diff, $t{$sr[0]}{$tier}{ave});
                $diff += round($t{$sr[0]}{$tier}{ave});
                $diff = round($diff,  10);
                push (@scores, $diff);
                $num_scores++;
            }
            last, if ($num_scores == $max_scores);
        }
        last, if ($num_scores == $max_scores);
    }

    #
    # League members that don't have more than 10 scores, allow
    # the use of the current handicap index.
    #
    if (($team ne "Sub") && ($num_scores < 10)) {
        print "$pn: league member with $num_scores scores.\n", if (0);
        return;
    }

    #
    # If the player does not have the required number of scores,
    # a handicap can not be generted for them.
    #
    if (($use = &nscores($num_scores)) == 0) {
        delete($league{$team}{$pn});
        untie %tnfb_db;
        print "$pn: only has $num_scores scores.\n", if (0);
        return;
    }

    @scores = sort {$a <=> $b} @scores;

    $hi = 0;

    for (my $y = 0; $y < $use; $y++) {
        #printf("$pn: score diff -> %.2f\n", $scores[$y]), if ($pn =~ /$name/);
        $hi += $scores[$y];
    }
    $hi /= $use;

    $hi /= 2;
    $hi = round($hi, 10);
    $hi = abs($hi), if ($hi == 0.0);
    print "$pn: $hi\n", if (0);
    $league{$team}{$pn}{hi} = $hi;
    #$tnfb_db{'Current'} = $hi;

    untie %tnfb_db;
}
