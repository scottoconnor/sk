#! /usr/bin/perl
#
# Copyright (c) 2018, 2024 Scott O'Connor
#

require './courses.pl';
require './tnfb.pl';
require './tnfb_years.pl';
require './hcroutines.pl';

use Getopt::Long;
use GDBM_File;

my ($debug) = 0;
my ($allowance) = 0.9;
my ($update_hi) = 0;
my ($hc);

GetOptions (
    "a=f" => \$allowance,
    "d" => \$debug,
    "u" => \$update_hi),
or die("Error in command line arguments\n");

my ($month) = (localtime)[4];
$month++;
my ($day) = (localtime)[3];
$year = (1900 + (localtime)[5]);

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

while ($fna = shift @golfer_list) {
    gen_hc("golfers/$fna", $year, $allowance);
}

print "$month-$day-$year              (sf sb nf nb)\n";

foreach $team (sort keys(%t)) {
    if ($team eq "Sub") {
        next;
    }
    printf("%s\n", $team);
    printf("%-17s %4.1fN /%2d %2d %2d %2d\n", $t{$team}{1}, $hc{$t{$team}{1}}{hi}, $hc{$t{$team}{1}}{sfhc},
        $hc{$t{$team}{1}}{sbhc}, $hc{$t{$team}{1}}{nfhc}, $hc{$t{$team}{1}}{nbhc});
    printf("%-17s %4.1fN /%2d %2d %2d %2d\n", $t{$team}{2}, $hc{$t{$team}{2}}{hi}, $hc{$t{$team}{2}}{sfhc},
        $hc{$t{$team}{2}}{sbhc}, $hc{$t{$team}{2}}{nfhc}, $hc{$t{$team}{2}}{nbhc});
    print "\n";
}

print "\014\n";
print "Sub\n";
foreach $p (sort keys %hc) {
    if ($hc{$p}{team} ne "Sub") {
        next;
    }
    if (defined($hc{$p}{hi})) {
        printf("%-17s %4.1fN /%2d %2d %2d %2d\n", $p, $hc{$p}{hi}, $hc{$p}{sfhc},
            $hc{$p}{sbhc}, $hc{$p}{nfhc}, $hc{$p}{nbhc});
    }
}

sub
gen_hc {
    my ($fn, $year, $allowance) = @_;
    my (@scores, $y, $hi, $use, @n, $pn, $x, $num_scores, $last_year);

    tie %tnfb_db, 'GDBM_File', $fn, GDBM_WRITER, 0644
        or die "$GDBM_File::gdbm_errno";

    #
    # Only add a player to the handicap list if they are active.
    #
    if ($tnfb_db{'Active'} == 0) {
        untie %tnfb_db;
        return;
    }

    ($first, $last) = split(/ /, $tnfb_db{'Player'}, 2);
    $pn = "$last, $first";
    $hc{$pn}{team} = $tnfb_db{'Team'};

    $last_year = 0;

    if ($pn eq "Kittredge, Red") {
        $debug = 1;
    } else {
        $debug = 0;
    }

    $num_scores = 0;
    foreach $y (reverse (1997..$year)) {
        foreach $w (reverse (1..15)) {
            if (exists($tnfb_db{$dates{$y}{$w}})) {
                push (@scores, $tnfb_db{$dates{$y}{$w}});
                $num_scores++;
                if ($last_year < $y) { $last_year = $y };
            }
            last, if ($num_scores == 20);
        }
        last, if ($num_scores == 20);
    }

    if ($num_scores < 20) {
        undef @scores;
        $last_year = 0;
        $num_scores = 0;
        foreach $y (reverse (1997..$year)) {
            foreach $m (reverse (1..12)) {
                foreach $d (reverse (1..31)) {
                    my $newdate = "$y-$m-$d";
                    if (exists($tnfb_db{$newdate})) {
                        push (@scores, $tnfb_db{$newdate});
                        $num_scores++;
                        if ($last_year < $y) { $last_year = $y };
                    }
                    last, if ($num_scores == 20);
                }
                last, if ($num_scores == 20);
            }
            last, if ($num_scores == 20);
        }
    }

    #
    # If a player hasn't posted a score in 7 years,
    # invalidate their handicap index.
    #
    if (($year - $last_year) > 7) {
        $tnfb_db{'Current'} = -100;
        untie %tnfb_db;
        return;
    }

    if ($num_scores > 20) {
        untie %tnfb_db;
        die "$pn: Number of score is more than 20.\n";
    }

    #
    # If the player does not have the required number of scores,
    # a handicap can not be generted for them.
    #
    if (($use = &nscores($num_scores)) == 0) {
        print "$pn: Only $num_scores scores, can not generate handicap\n", if $debug;
        $tnfb_db{'Current'} = -100;
        untie %tnfb_db;
        return;
    }

    $y = 0;
    foreach my $s (@scores) {

        ($course, $course_rating, $slope, $date, $aa, $bb, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
            split(/:/, $s);

        print "$course, $course_rating, $slope, $date, $shot, $post\n", if $debug;

        $n[$y] = ((113 / $slope) * ($post - $course_rating));

        #
        # Round to the nearest tenth.
        #
        $n[$y] = round($n[$y], 10);
        printf("date=%s: post=%d: differential: %.1f\n", $date, $post, $n[$y]), if $debug;

        $y++;
    }

    @n = sort {$a <=> $b} @n;

    $hi = 0;

    for ($y = 0; $y < $use; $y++) {
        printf("%d: %.1f\n", $y, $n[$y]), if $debug;
        $hi += $n[$y];
    }

    $hi /= $use;

    if ($update_hi == 0) {
        $hi = $tnfb_db{'Current'};
    }

    if ($hi == -100) {
        untie %tnfb_db;
        return;
    }

    if ($pn eq "O'Connor, S") {
        $hi = 6.1;
    }

    $hi = round($hi, 10);

    $sfd = ($c{SF}{course_rating} - $c{SF}{par});
    $sfd = round($sfd, 10);
    $sf = (($hi * ($c{SF}->{slope} / 113)) + $sfd);
    $sf = sprintf("%.0f", ($sf * $allowance));

    $sbd = ($c{SB}{course_rating} - $c{SB}{par});
    $sbd = round($sbd, 10);
    $sb = (($hi * ($c{SB}->{slope} / 113)) + $sbd);
    $sb = sprintf("%.0f", ($sb * $allowance));

    $nfd = ($c{NF}{course_rating} - $c{NF}{par});
    $nfd = round($nfd, 10);
    $nf = (($hi * ($c{NF}->{slope} / 113)) + $nfd);
    $nf = sprintf("%.0f", ($nf * $allowance));

    $nbd = ($c{NB}{course_rating} - $c{NB}{par});
    $nbd = round($nbd, 10);
    $nb = (($hi * ($c{NB}->{slope} / 113)) + $nbd);
    $nb = sprintf("%.0f", ($nb * $allowance));

    $hc{$pn}{hi} = $hi;
    $hc{$pn}{sfhc} = $sf;
    $hc{$pn}{sbhc} = $sb;
    $hc{$pn}{nfhc} = $nf;
    $hc{$pn}{nbhc} = $nb;

    if ($update_hi == 1) {
        $tnfb_db{'Current'} = $hi;
    }

    untie %tnfb_db;
}
