#! /usr/bin/perl
#
# Copyright (c) 2018, 2022 Scott O'Connor
#

require './courses.pl';
require './tnfb.pl';
require './hcroutines.pl';

use Getopt::Long;

$debug = 0;
$trend = 0;
$allowance = 0.9;

GetOptions (
    "a=f" => \$allowance,
    "t" =>  \$trend,
    "d" => \$debug)
or die("Error in command line arguments\n");

$month = (localtime)[4];
$month++;
$day = (localtime)[3];
$year = (1900 + (localtime)[5]);

#
# Years prior to 2020, we use the USGA method of handicapping.
# 2020 and beyond, we use the World Handicapping System.
#
if ($year > 2019) {
    $usga = 0;
} else {
    $usga = 1;
}

#
# Only used files processed by skcon.pl (ScoreKeeper Convert).
#
opendir($dh, "./golfers") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ =~ /(^1\d{3}$)/) {
        push @golfer_list, $_;
    }
}
closedir ($dh);

@golfer_list = sort @golfer_list;

if (@golfer_list == 0) {
    exit;
}

while ($fna = shift @golfer_list) {
    if ($trend) {
        gen_hc_trend("golfers/$fna", $allowance);
    } else {
        gen_hc("golfers/$fna", $allowance);
    }
}

if ($trend == 0) {

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
}

sub gen_hc {
    my ($fn, $allowance) = @_;
    my (@scores, $y, $hi, $use, @n, $pn);

    undef @n;

    open(FD, $fn);
    @scores = <FD>;
    close(FD);

    chomp($scores[0]);
    ($first, $last, $team, $active) = split(/:/, $scores[0]);
    $pn = $last . ", " . $first;

    if ($pn eq "Kittredge, Red") {
        $debug = 1;
    } else {
        $debug = 0;
    }

    if ($active == 0) {
        return;
    }

    $hc{$pn}{team} = $team;

    shift @scores;

    $num = @scores;

    #
    # If the golfer has more than 20 scores, only grab the last 20.
    #
    if ($num > 20) {
        @scores = splice(@scores, ($num - 20), 20);
        $num = @scores;
    }

    $y = 0;
    foreach my $s (@scores) {

        chomp($s);
        ($course, $course_rating, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
            split(/:/, $s);

        if ($post == 100) {
            print "Bogus posted score of -> $post, need to fix.\n";
        }

        print "$course, $course_rating, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni\n", if $debug;

        $n[$y] = ((113 / $slope) * ($post - $course_rating));

        if ($shot > 75) {
            $n[$y] /= 2;
        }

        #
        # Round to the nearest tenth.
        #
        $n[$y] = round($n[$y], 10);
        printf("date=%s: post=%d: differential: %.1f\n", $date, $post, $n[$y]), if $debug;

        $y++;
    }

    #
    # If the player does not have the required number of scores,
    # a handicap can not be generted for them.
    #
    if (($use = &nscores($num, $usga)) == 0) {
        print "$pn: Only $num scores, can not generate handicap\n", if $debug;
        return;
    }

    @n = sort {$a <=> $b} @n;

    $hi = 0;

    for ($y = 0; $y < $use; $y++) {
        printf("%d: %.1f\n", $y, $n[$y]), if $debug;
        $hi += $n[$y];
    }

    $hi /= $use;

    if ($pn eq "O'Connor, S") {
        $hi = 9.8;
    }

    if ($usga) {
        $hi *= $allowance;
        $hi = (int($hi * 10) / 10);
        $sf = ($hi * $c{SF}->{slope} / 113);
        $sf = sprintf("%.0f", $sf);
        $sb = ($hi * $c{SB}->{slope} / 113);
        $sb = sprintf("%.0f", $sb);
        $nf = ($hi * $c{NF}->{slope} / 113);
        $nf = sprintf("%.0f", $nf);
        $nb = ($hi * $c{NB}->{slope} / 113);
        $nb = sprintf("%.0f", $nb);
    } else {
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
    }

    $hc{$pn}{hi} = $hi;
    $hc{$pn}{sfhc} = $sf;
    $hc{$pn}{sbhc} = $sb;
    $hc{$pn}{nfhc} = $nf;
    $hc{$pn}{nbhc} = $nb;

    printf ("%-17s - %5.1fN  SF=%-3d SB=%-3d NF=%-3d NB=%-3d\n", $pn, $hi, $sf, $sb, $nf, $nb), if $debug;
}
