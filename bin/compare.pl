#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use File::Compare;
use Text::Diff;
use GDBM_File;

my ($diff, $dh, $workingpath, $beforepath);

$diff = 0;
my ($end_year) = (1900 + (localtime)[5]);

$beforepath = "/home/soconnor/backup";
$workingpath = "/home/soconnor/sk/golfers";

#
# Open the league directory and only read the Gnu database files.
#
opendir($dh, $workingpath) || die "Can't open \"$workingpath\" directory.";

while (readdir $dh) {
    if ($_ =~ /(^1\d{3}$\.gdbm)/) {
        my $before = "$beforepath/$_";
        my $after = "$workingpath/$_";
        tie my %tnfb_db, 'GDBM_File', $after, GDBM_READER, 0640
            or die "$GDBM_File::gdbm_errno";
        my $pn = $tnfb_db{'Player'};
        untie %tnfb_db;
        print_db($after, "after");
        print_db($before, "before");
        if (compare("/tmp/before", "/tmp/after") == 1) {
            print "Player: $pn\n";
            my $diffs = diff '/tmp/before' => '/tmp/after';
            print STDOUT "$diffs";
            print STDOUT "file -> $_\n\n";
            $diff++;
        }
        unlink "/tmp/before";
        unlink "/tmp/after";
    }
}
closedir ($dh);
print STDOUT "There are $diff compare errors\n";

sub
print_db {
    my ($file, $output) = @_;
    my (%tnfb_db);

    if (!-e $file) {
        die "$file: Does not exists.\n";
    }

    tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0640
        or die "$GDBM_File::gdbm_errno";

    my ($y, $m, $d, $team);
    my ($scores) = 0;

    open (my $log, ">", "/tmp/$output");

    foreach $y (1997..$end_year) {
        $team = "Team_$y";
        if (exists($tnfb_db{$team})) {
            print $log "$team: $tnfb_db{$team}\n";
        }
        foreach $m (4..12) {
            foreach $d (1..31) {
                my $date = "$y-$m-$d";
                if (exists($tnfb_db{$date})) {
                    print $log "$date: $tnfb_db{$date}\n";
                    $scores++;
                }
            }
        }
    }

    print $log "Name: $tnfb_db{'Player'}\n";
    if (exists($tnfb_db{'Team'})) {
        print $log "Team: $tnfb_db{'Team'}\n";
    }
    if (exists($tnfb_db{'Active'})) {
        print $log "Active: $tnfb_db{'Active'}\n";
    }
    if (exists($tnfb_db{'Golf'})) {
        print $log "Golf: $tnfb_db{'Golf'}\n";
    }
    if (exists($tnfb_db{'Current'})) {
        printf $log "Current: %.1f\n", $tnfb_db{'Current'};
    }
    if (exists($tnfb_db{'new_hi'})) {
        printf $log "new_hi: %.1f\n", $tnfb_db{'new_hi'};
    }
    print $log "Number of scores: $scores\n";

    close($log);
    untie %tnfb_db;
}
