#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use warnings;
use Time::Piece;
use Time::Seconds;
use GDBM_File;
use Time::HiRes qw(gettimeofday);

# Get current year
my $end_year = localtime->year;
my $sy;
my $bad_scores = 0;
my $all_scores = 0;
my $t;
my ($year, $month, $day, $date);
my %tnfb_db;
my @file_list;
my $league = './golfers';
my $dh;

my $t0 = gettimeofday();

opendir($dh, "$league") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ =~ /(^1\d{3}\056gdbm)/) {
        tie %tnfb_db, 'GDBM_File', "$league/$_", GDBM_READER, 0644
            or die "$GDBM_File::gdbm_errno";
        push(@file_list, $_);
        untie %tnfb_db;
    }
}
closedir ($dh);

@file_list = sort @file_list;

while (my $file = shift @file_list) {

    my $scores = 0;

    tie %tnfb_db, 'GDBM_File', "$league/$file", GDBM_READER, 0644
        or die "$GDBM_File::gdbm_errno";

    my $pn = $tnfb_db{'Player'};

    $sy = 1997;
    $t = Time::Piece->strptime("$sy-04-20", "%Y-%m-%d");

    while ($sy <= $end_year) {

        #
        # We can check if a player has a team for this year, either Unknown, Sub or
        # league member. If they do not have a team that they played for, they did
        # not play this year and this year can be skipped.
        #
        if (!exists($tnfb_db{"Team_$sy"})) {
            $sy++;
            $t = Time::Piece->strptime("$sy-04-20", "%Y-%m-%d");
            next;
        }

        ($year, $month, $day) = $t->ymd =~ /(\d{4})-\060*(\d{1,2})-\060*(\d{1,2})/;
        $date = "$year-$month-$day";

        # Check if the day is Tuesday
        if ((exists($tnfb_db{$date})) && ($t->fullday eq 'Tuesday')) {
            if (check_score($pn, $date, $tnfb_db{$date})) {
                $bad_scores++;
            }
            $scores++;
        } elsif ((exists($tnfb_db{$date})) && ($t->fullday ne 'Tuesday')) {
            print "$pn: $date, non-tuesday score.\n";
            $bad_scores++;
        }

        $t += ONE_DAY;

        if ($t->mon > 8) {
            $sy++;
            $t = Time::Piece->strptime("$sy-04-20", "%Y-%m-%d");
        }
    }

    printf("%-18s = %s (%d)\n", $pn, $file, $scores);
    $all_scores += $scores;

    untie %tnfb_db;
}

my $t1 = gettimeofday();
my $total_time = ($t1 - $t0);

printf("All Scores = %d - %d bad score(s) found\n", $all_scores, $bad_scores);
printf("Total time = %.2f seconds\n", $total_time);

sub
check_score
{
    my ($pn, $date, $s) = @_;
    my @sr = split(/:/, $s);
    my $ret = 0;

    print "@sr\n", if (0);

    if (scalar(@sr) < 17) {
        print "$pn: $date, scoring record is less than 17\n";
        $ret = 1;
    }
    if ($sr[0] ne "SF" && $sr[0] ne "SB" && $sr[0] ne "NF" && $sr[0] ne "NB") {
        print "$pn: $date, bad course: $sr[0]\n";
        $ret = 1;
    }
    if ($date ne $sr[3]) {
        print "$pn: $date, dates don't match: $s\n";
        $ret = 1;
    }
    return ($ret);
}
