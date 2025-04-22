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
my (undef($name));
my ($debug) = 0;
my (%tnfb_db, %league, $dh);
my ($max_scores) = 20;
my ($sf, $sb, $nf, $nb);
our (%c);
our (%dates);

GetOptions (
    "x" => \$expected_diff,
    "d" => \$debug,
    "n=s" => \$name,
    "a=f" => \$allowance),
or die("Error in command line arguments\n");

my ($month) = (localtime)[4];
$month++;
my ($day) = (localtime)[3];
my ($year) = (1900 + (localtime)[5]);

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
        printf("%-18s %4.1fN /%2d %2d %2d %2d%s\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb,
            $tnfb{$pn}{aging}), if !defined($name);
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
        printf("%-18s %4.1fN /%2d %2d %2d %2d%s\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb,
            $tnfb{$pn}{aging}), if !defined($name);
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

    my (%tnfb_db, $use, @sr, $diff, %pc, $hi, %pd, $by, $id, $nd);

    tie %tnfb_db, 'GDBM_File', $fn, GDBM_READER, 0644
        or die "$GDBM_File::gdbm_errno";

    my ($first, $last) = split(/ /, $tnfb_db{'Player'}, 2);

    my $pn = "$last, $first";
    my $team = $tnfb_db{'Team'};
    my $hi = $tnfb_db{'Current'};

    undef(my @scores);
    my $num_scores = 0;
    $by = ($year - 5);

    foreach my $y (reverse ($by..$year)) {
        foreach my $w (reverse (1..15)) {
            if (exists($tnfb_db{$dates{$y}{$w}})) {
                @sr = split(/:/, $tnfb_db{$dates{$y}{$w}});
                $diff = round(((113 / $sr[2]) * ($sr[7] - $sr[1])),  10);
                my $index_diff = ($diff - $hi);
                $diff = calc_xd($pn, $index_diff, $diff, $hi);
                $diff = round($diff,  10);
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
        delete($league{$team}{$pn});
        untie %tnfb_db;
        return;
    }

    $league{$team}{$pn}{aging} = "";
    #if ($use < 5) {
        #printf("%s : use -> %d\n", $pn, $use), if ($pn =~ /$name/);
        #$league{$team}{$pn}{aging} = "*";
    #}

    @scores = sort {$a <=> $b} @scores;

    $hi = 0;

    for (my $y = 0; $y < $use; $y++) {
        printf("score diff -> %.2f\n", $scores[$y]), if ($pn =~ /$name/);
        $hi += $scores[$y];
    }
    $hi /= $use;

    $hi /= 2;
    $hi = round($hi, 10);
    $hi = abs($hi), if ($hi == 0.0);

    $league{$team}{$pn}{hi} = $hi;

    untie %tnfb_db;
}

sub
calc_xd {
    my ($pn, $id, $diff, $hi) = @_;
    my ($nd, $hid, $d, $new_diff);

    $d = 1.0;
    if ($id <= -5) {
        $nd = ($hi * $d);
        $nd += 2.0;
    }
    $d = 1.1;
    if ($id <= -4 && $id > -5) {
        $nd = ($hi * $d);
        $nd += 1.75;
    }
    $d = 1.2;
    if ($id <= -3 && $id > -4) {
        $nd = ($hi * $d);
        $nd += 1.5;
    }
    $d = 1.3;
    if ($id <= -2 && $id > -3) {
        $nd = ($hi * $d);
        $nd += 1.0;
    }
    $d = 1.4;
    if ($id <= -1.5 && $id > -2) {
        $nd = ($hi * $d);
        $nd += 0.5;
    }

    if ($id > -1.5 && $id < 1.5) {
        $nd = $hi;
    }

    my $d = 1.4;
    if ($id >= 1.5 && $id < 2) {
        $nd = ($hi * $d);
    }
    my $d = 1.5;
    if ($id >= 2 && $id < 3) {
        $nd = ($hi * $d);
    }
    my $d = 1.6;
    if ($id >= 3 && $id < 4) {
        $nd = ($hi * $d);
    }
    my $d = 1.7;
    if ($id >= 4 && $id < 5) {
        $nd = ($hi * $d);
    }
    my $d = 1.8;
    if ($id >= 5) {
        $nd = ($hi * $d);
    }

    $new_diff = ($diff + $nd);
    return ($new_diff);
}
