#! /usr/bin/perl
#
# Copyright (c) 2018, 2024 Scott O'Connor
#

use strict;
require './courses.pl';
require './tnfb_years.pl';
require './hcroutines.pl';

use Getopt::Long;
use GDBM_File;

my ($allowance) = 0.9;
my ($expected_diff) = 0;
my (%tnfb_db, %league, $dh);
my ($max_scores) = 20;
my ($sf, $sb, $nf, $nb);
our (%c);
our (%dates);

GetOptions (
    "x" => \$expected_diff,
    "a=f" => \$allowance),
or die("Error in command line arguments\n");

my ($month) = (localtime)[4];
$month++;
my ($day) = (localtime)[3];
my ($year) = (1900 + (localtime)[5]);
my ($back_year) = ($year - 5);

#
# Read the Gnu database files.
#
opendir($dh, "./golfers") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ =~ /(^1\d{3}\056gdbm)/) {
        tie %tnfb_db, 'GDBM_File', "golfers/$_", GDBM_READER, 0644
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
            expected_diff("golfers/$_");
        }
    }
}
closedir ($dh);

print "$month-$day-$year               (sf sb nf nb)\n";

#
# First, print out the league members.
#
foreach my $team (sort keys(%league)) {
    if ($team eq "Sub") {
        next;
    }
    print "$team\n";
    my %tnfb = %{$league{$team}};
    foreach my $pn (sort keys %tnfb) {
        ($sf, $sb, $nf, $nb) = gen_handicap($tnfb{$pn}{hi});
        printf("%-18s %4.1fN /%2d %2d %2d %2d\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb);
    }
    print "\n";
}

#
# Now print out the subs.
#
foreach my $team (sort keys(%league)) {
    if ($team ne "Sub") {
        next;
    }
    print "$team\n";
    my %tnfb = %{$league{$team}};
    foreach my $pn (sort keys %tnfb) {
        ($sf, $sb, $nf, $nb) = gen_handicap($tnfb{$pn}{hi});
        printf("%-18s %4.1fN /%2d %2d %2d %2d\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb);
    }
}

sub
gen_handicap {
    my ($hi) = @_;

    my $sfd = ($c{SF}{course_rating} - $c{SF}{par});
    my $sf = (($hi * ($c{SF}->{slope} / 113)) + $sfd);
    $sf *= $allowance;
    $sf = round($sf, 1);

    my $sbd = ($c{SB}{course_rating} - $c{SB}{par});
    my $sb = (($hi * ($c{SB}->{slope} / 113)) + $sbd);
    $sb *= $allowance;
    $sb = round($sb, 1);

    my $nfd = ($c{NF}{course_rating} - $c{NF}{par});
    my $nf = (($hi * ($c{NF}->{slope} / 113)) + $nfd);
    $nf *= $allowance;
    $nf = round($nf, 1);

    my $nbd = ($c{NB}{course_rating} - $c{NB}{par});
    my $nb = (($hi * ($c{NB}->{slope} / 113)) + $nbd);
    $nb *= $allowance;
    $nb = round($nb, 1);

    return ($sf, $sb, $nf, $nb);
}

sub
expected_diff {
    my ($fn) = @_;

    my (%tnfb_db, $use, @sr, $diff, %pc, $hi, %pd);

    tie %tnfb_db, 'GDBM_File', $fn, GDBM_READER, 0644
        or die "$GDBM_File::gdbm_errno";

    my $by = $back_year;
    if ($tnfb_db{'Team'} eq "Sub") {
        $by = 2010;
    }

    my ($first, $last) = split(/ /, $tnfb_db{'Player'}, 2);

    my $pn = "$last, $first";
    my $team = $tnfb_db{'Team'};

    my $num_scores = 0;

    foreach my $y ($by..$year) {
        foreach my $w (1..15) {
            if (exists($tnfb_db{$dates{$y}{$w}})) {
                @sr = split(/:/, $tnfb_db{$dates{$y}{$w}});
                $diff = ((113 / $sr[2]) * ($sr[7] - $sr[1]));
                $diff = round($diff, 10);
                $pc{$sr[0]}{swings} += $diff;
                $pc{$sr[0]}{xplayed}++;
            }
        }
    }

    my $adjust = 0.0;
    if ($pc{'SF'}{xplayed}) {
        $pd{'SF'} = ($pc{'SF'}{swings} / $pc{'SF'}{xplayed});
        $pd{'SF'} += $adjust;
        printf("%s: pd[SF] = %.1f\n", $pn, $pd{'SF'}), if 0;
    }

    if ($pc{'SB'}{xplayed}) {
        $pd{'SB'} = ($pc{'SB'}{swings} / $pc{'SB'}{xplayed});
        $pd{'SB'} += $adjust;
        printf("%s: pd[SB] = %.1f\n", $pn, $pd{'SB'}), if 0;
    }

    if ($pc{'NF'}{xplayed}) {
        $pd{'NF'} = ($pc{'NF'}{swings} / $pc{'NF'}{xplayed});
        $pd{'NF'} += $adjust;
        printf("%s: pd[NF] = %.1f\n", $pn, $pd{'NF'}), if 0;
    }

    if ($pc{'NB'}{xplayed}) {
        $pd{'NB'} = ($pc{'NB'}{swings} / $pc{'NB'}{xplayed});
        $pd{'NB'} += $adjust;
        printf("%s: pd[NB] = %.1f\n", $pn, $pd{'NB'}), if 0;
    }

    $diff = 0;
    $num_scores = 0;
    undef(my @scores);
    foreach my $y (reverse ($by..$year)) {
        foreach my $w (reverse (1..15)) {
            if (exists($tnfb_db{$dates{$y}{$w}})) {
                @sr = split(/:/, $tnfb_db{$dates{$y}{$w}});
                $diff = ((113 / $sr[2]) * ($sr[7] - $sr[1]));
                $diff += $pd{$sr[0]};
                push (@scores, $diff);
                $num_scores++;
            }
            last, if ($num_scores == $max_scores);
        }
        last, if ($num_scores == $max_scores);
    }

    #
    # If the player does not have the required number of scores,
    # a handicap can not be generted for them.
    #
    if (($use = &nscores($num_scores)) == 0) {
        untie %tnfb_db;
        return;
    }

    @scores = sort {$a <=> $b} @scores;

    $hi = 0;

    for (my $y = 0; $y < $use; $y++) {
        printf("%d: %.1f\n", $y, $scores[$y]), if 0;
        $hi += $scores[$y];
    }
    $hi /= $use;

    $hi /= 2;
    $hi = round($hi, 10);

    $league{$team}{$pn}{hi} = $hi;

    untie %tnfb_db;
}
