#! /usr/bin/perl
#
# Copyright (c) 2018, 2024 Scott O'Connor
#

require './courses.pl';
require './tnfb_years.pl';
require './hcroutines.pl';

use Getopt::Long;
use GDBM_File;

my ($debug) = 0;
my ($allowance) = 0.9;
my ($league, $dh, $fna);
my (@golfer_list);

GetOptions (
    "a=f" => \$allowance,
    "d" => \$debug),
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
    if ($_ =~ /(^1\d{3}$\.gdbm)/) {
        push @golfer_list, $_;
    }
}
closedir ($dh);

@golfer_list = sort @golfer_list;

#
# Get each players handicap index.
#
while ($fna = shift @golfer_list) {

    tie %tnfb_db, 'GDBM_File', "golfers/$fna", GDBM_WRITER, 0644
        or die "$GDBM_File::gdbm_errno";

    #
    # Only add a player to the handicap list if they are active
    # and have a valid handicap index.
    #
    if ($tnfb_db{'Active'} == 0 || $tnfb_db{'Current'} == -100) {
        untie %tnfb_db;
        next;
    }

    ($first, $last) = split(/ /, $tnfb_db{'Player'}, 2);
    $pn = "$last, $first";

    $league{$tnfb_db{'Team'}}{$pn}{hi} = $tnfb_db{'Current'};

    untie %tnfb_db;
}

print "$month-$day-$year              (sf sb nf nb)\n";

#
# First, print out the league members.
#
foreach $team (sort keys(%league)) {
    if ($team eq "Sub") {
        next;
    }
    print "$team\n";
    %tnfb = %{$league{$team}};
    foreach my $key (sort keys %tnfb) {
        ($sf, $sb, $nf, $nb) = gen_handicap($tnfb{$key}{hi});
        printf("%-17s %4.1fN /%2d %2d %2d %2d\n", $key, $tnfb{$key}{hi}, $sf, $sb, $nf, $nb);
    }
    print "\n";
}

print "\014\n";

#
# Now print out the subs.
#
foreach $team (sort keys(%league)) {
    if ($team ne "Sub") {
        next;
    }
    print "$team\n";
    %tnfb = %{$league{$team}};
    foreach my $key (sort keys %tnfb) {
        ($sf, $sb, $nf, $nb) = gen_handicap($tnfb{$key}{hi});
        printf("%-17s %4.1fN /%2d %2d %2d %2d\n", $key, $tnfb{$key}{hi}, $sf, $sb, $nf, $nb);
    }
}

sub
gen_handicap {
    my ($hi) = @_;

    $sfd = ($c{SF}{course_rating} - $c{SF}{par});
    $sf = (($hi * ($c{SF}->{slope} / 113)) + $sfd);
    $sf *= $allowance;
    $sf = round($sf, 1);

    $sbd = ($c{SB}{course_rating} - $c{SB}{par});
    $sb = (($hi * ($c{SB}->{slope} / 113)) + $sbd);
    $sb *= $allowance;
    $sb = round($sb, 1);

    $nfd = ($c{NF}{course_rating} - $c{NF}{par});
    $nf = (($hi * ($c{NF}->{slope} / 113)) + $nfd);
    $nf *= $allowance;
    $nf = round($nf, 1);

    $nbd = ($c{NB}{course_rating} - $c{NB}{par});
    $nb = (($hi * ($c{NB}->{slope} / 113)) + $nbd);
    $nb *= $allowance;
    $nb = round($nb, 1);

    return ($sf, $sb, $nf, $nb);
}
