#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use Time::Piece;
use Time::Seconds;
use GDBM_File;
use warnings;

require './tnfb_years.pl';

# Get current year
my $end_year = localtime->year;
my $sy;
my ($bad_scores) = 0;
my ($all_scores) = 0;
my ($na_scores) = 0;
my $t;
my $rw;
my ($year, $month, $day, $date);
my (%tnfb_db);

for (my $x = 1000; $x <= 1300; $x++) {
    my $file = "golfers/$x.gdbm";

    if (! -e $file) {
        next;
    }

    $rw = GDBM_READER;
    #$rw = GDBM_WRITER;
    my ($scores) = 0;

    tie %tnfb_db, 'GDBM_File', $file, $rw, 0644
        or die "$GDBM_File::gdbm_errno";

    my $pn =  $tnfb_db{'Player'};

    if (($tnfb_db{'Team'} ne "Sub") && 0) {
        print "$tnfb_db{'Player'} skipping...\n";
        untie %tnfb_db;
        next;
    }

    $sy = 1997;
    $t = Time::Piece->strptime("$sy-04-01", "%Y-%m-%d");

    while ($sy <= $end_year) {

        ($year, $month, $day) = $t->ymd =~ /(\d{4})-\060*(\d+)-\060*(\d+)/;
        $date = "$year-$month-$day";
        print "date = $date\n", if (0);

        if (!exists($tnfb_db{$date})) {
            # Move to next day
            $t += ONE_DAY;
            ($sy) = $t->year =~ /(\d\d\d\d)/;
            next;
        }

        # Check if the day is Tuesday
        if ((exists($tnfb_db{$date})) && ($t->fullday eq 'Tuesday')) {
            print "$tnfb_db{'Player'}: $date, $tnfb_db{$date}\n", if (0);
        } elsif ((exists($tnfb_db{$date})) && ($t->fullday ne 'Tuesday')) {
            print "$tnfb_db{'Player'}: $date, non-tuesday score?\n", if (1);
            if ($tnfb_db{'Player'} eq "xxxSpates") {
                print "Score needing deletion on $date for $tnfb_db{'Player'}\n";
                #delete($tnfb_db{$date}), if ($rw eq GDBM_WRITER);
            }
            $bad_scores += 1;
        }

        $scores++;
        $bad_scores += check_score($pn, $date, $tnfb_db{$date});

        # Move to next day
        $t += ONE_DAY;
        ($sy) = $t->year =~ /(\d\d\d\d)/;
    }

    printf("%-18s = %s (%d)\n", $tnfb_db{'Player'}, $file, $scores);
    $all_scores += $scores;

    untie %tnfb_db;
}

printf("All Scores = %d - %d issues found\n", $all_scores, $bad_scores);
print "Scores with NA/NA = $na_scores\n", if ($na_scores > 0);

sub
check_score
{
    my($pn, $date, $s) = @_;
    my @sr = split(/:/, $s);
    my $ret = 0;

    print "@sr\n", if (0);

    if (scalar(@sr) < 17) {
        print "Scoring record is less than 17: $pn, $date\n";
        $ret = 1;
    }
    if ($sr[0] ne "SF" && $sr[0] ne "SB" && $sr[0] ne "NF" && $sr[0] ne "NB") {
        print "Bad course: $sr[0], $date, $pn\n";
        $ret = 1;
    }
    if ($sr[4] eq "NA" && $sr[5] eq "NA") {
        $na_scores++;
        print "Need deleting: $pn on $date: $sr[3]: $sr[4] and $sr[5]\n", if (0);
        #delete($tnfb_db{$date}), if ($rw eq GDBM_WRITER);
        $ret = 1;
    }
    if ($date ne $sr[3]) {
        print "dates don't match: $pn: $date: $s\n";
        $ret = 1;
    }
    return ($ret);
}
