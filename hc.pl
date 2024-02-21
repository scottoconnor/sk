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
my (%tnfb_db, %league, $dh);
my ($sf, $sb, $nf, $nb);
our (%c);

GetOptions (
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
        printf("%-17s %4.1fN /%2d %2d %2d %2d\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb);
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
        printf("%-17s %4.1fN /%2d %2d %2d %2d\n", $pn, $tnfb{$pn}{hi}, $sf, $sb, $nf, $nb);
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
