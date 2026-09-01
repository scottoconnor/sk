#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use GDBM_File;

my $path;
my $dh;
my @golfer_list;
my %tnfb_db;

$path = "/home/soconnor/sk/golfers";

opendir($dh, $path) || die "Can't open directory.";

while (readdir $dh) {
    if ($_ =~ /(^1\d{3}\056gdbm)/) {
        push @golfer_list, "$path/$_";
    }
}
closedir ($dh);

@golfer_list = sort @golfer_list;

while (my $fn = shift @golfer_list) {

    tie %tnfb_db, 'GDBM_File', $fn, GDBM_READER, 0644
        or die "$GDBM_File::gdbm_errno";

    if ($tnfb_db{'Team'} eq "Sub") {
        untie %tnfb_db;
        next;
    }

    my $pn = $tnfb_db{'Player'};

    my (undef(@sr));
    my (undef(@scores));
    my $num = 0;
    my $total = 0;
    foreach my $date (keys %tnfb_db) {

        #
        # If the key is not a 'date' (yyyy-m+-d+), skip.
        #
        if ($date !~ /\d{4}\055\d+\055\d+/) {
            next;
        }

        @sr = split(/:/, $tnfb_db{$date});

        push @scores, $sr[6];
        $total += $sr[6];
        $num++;
    }

    if ($num > 0) {
        my $ave_one = ($total / $num);
        printf("%-17s: average score = %.2f, ", $pn, $ave_one);

        my @scores = sort @scores;
        my $num_scores = @scores;
        my $num = $num_scores = int($num_scores * 0.25);

        my $total = 0;
        while ($num_scores--) {
            $total += shift(@scores);
        }

        my $ave_two = ($total / $num), if ($num > 0); 
        printf("average score of best 25%% scores = %.2f - diff %.2f\n", $ave_two, ($ave_one - $ave_two));
    }

    untie %tnfb_db;
}
