#! /usr/bin/perl
#
# Copyright (c) 2018, 2019 Scott O'Connor
#

require './courses.pl';
require './tnfb.pl';
require './hcroutines.pl';

use Getopt::Long;

$debug = 0;
$trend = 0;
$convert = 0;
$output = 1;

GetOptions (
    "t" =>  \$trend,
    "c" =>  \$convert,
    "d" => \$debug)
or die("Error in command line arguments\n");

$month = (localtime)[4];
$month++;
$day = (localtime)[3];
$year = (1900 + (localtime)[5]);

if ($convert) {
    print "$month-$day-$year";
    &con_skhist;
    exit;
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
	gen_hc_trend("golfers/$fna", $output);
    } else {
	gen_hc("golfers/$fna");
    }
}

if ($trend == 0) {

    print "$month-$day-$year\n";

    foreach $team (sort keys(%t)) {
	if ($team eq "Sub") {
	    next;
	}
	printf("%s\n", $team);
	printf("%-17s %4.1fN / %d\n", $t{$team}{1}, $hc{$t{$team}{1}}{hi}, $hc{$t{$team}{1}}{hc});
	printf("%-17s %4.1fN / %d\n", $t{$team}{2}, $hc{$t{$team}{2}}{hi}, $hc{$t{$team}{2}}{hc});
	print "\n";
    }

    print "\014\n";
    print "Sub\n";
    foreach $p (sort keys %hc) {
	if ($hc{$p}{team} ne "Sub") {
	    next;
	}
	if (defined($hc{$p}{hc})) {
	    printf("%-17s %4.1fN / %d\n", $p, $hc{$p}{hi}, $hc{$p}{hc});
	}
    }
}

sub gen_hc {
    my ($fn) = @_;
    my (@scores, $y, $hi, $use, @n, $pn);

    undef @n;

    open(FD, $fn);
    @scores = <FD>;
    close(FD);

    chomp($scores[0]);
    ($first, $last, $team, $active) = split(/:/, $scores[0]);
    $pn = $last . ", " . $first;

    if ($pn eq "Elkort, Mike") {
	#$debug = 1;
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
    # If player has less than 5 scores, a handicap can not be generated.
    #
    if ($num < 5) {
	print "$pn: Only $num scores, can not generate handicap\n", if $debug;
	return;
    }

    #
    # If the golfer has more than 20 scores, only grab the last 20.
    #
    if ($num > 20) {
	@scores = splice(@scores, ($num - 20), 20);
    }

    #
    # Using the USGA formula, determine how many scores will be used
    # to generate this player handicap.
    #
    $use = &nscores($num);

    $y = 0;
    foreach my $s (@scores) {

	chomp($s);
	($course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni) =
	    split(/:/, $s);

	print "$course, $par, $slope, $date, $shot, $post, $o, $t, $th, $f, $fv, $s, $sv, $e, $ni\n", if $debug;

	$n[$y] = ((($post - $par) * 113) / $slope);

	if ($shot > 75) {
	    $n[$y] /= 2;
	}

	#
	# First round to the nearest hundredth, then to the tenth.
	#
	$n[$y] = sprintf("%0.1f",$n[$y]);
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
    $hi *= 0.90;  # 90% is used for match play
    $hi = (int($hi * 10) / 10);

    #if ($pn eq "O'Connor, Scott") {
	#$hi = 1.9;
    #}

    $sf = int(($hi * $c{SF}->{slope} / 113) + 0.5);
    $sb = int(($hi * $c{SB}->{slope} / 113) + 0.5);
    $nf = int(($hi * $c{NF}->{slope} / 113) + 0.5);
    $nb = int(($hi * $c{NB}->{slope} / 113) + 0.5);

    $hc{$pn}{hi} = $hi;
    $hc{$pn}{hc} = $sf;
    printf ("%-17s - %5.1fN  SF=%-3d SB=%-3d NF=%-3d NB=%-3d\n", $pn, $hi, $sf, $sb, $nf, $nb), if $debug;
}

sub con_skhist {

    open (FD, "skhist.txt") || die "skhist.txt does not exist.\n";

    while (<FD>) {

	if ($_ =~ /^All\s+Hand/) {
	    ($date) = $_ =~ /\: (\d+\055\d+\055\d+)/;
	    #print "$date\n";
	}

	if ($_ =~ /^\s+/) {
	    next;
	}

	if ($_ =~ /^TNFB/) {
	    $team = "TNFB"; 
	    $_ =~ s/^\s+|\s+$//g;
	    print "\n$_\n";
	}

	if ($team eq "TNFB") {
	    if (($last, $first, $index, $hc) = $_ =~ /^(\S+)\054\s*(\S+)\s+(\d+\056\d+)N\s+\/\s+(\d+)/) {
		$pn = $last . ", " . $first;
		printf("%-17s %4.1fN / %d\n", $pn, $index, $hc);
	    }
	}
    }

    seek(FD, 0, SEEK_SET);

    while (<FD>) {

	if ($_ =~ /^\s+/) {
	    next;
	}

	if ($_ =~ /Sub/) {
	    $team = "Sub";
	    print "\n\014\n";
	    $_ =~ s/^\s+|\s+$//g;
	    print "$_\n";
	}

	if ($_ =~ /^TNFB/) {
	    $team = "TNFB";
	}

	if ($team eq "Sub") {
	    if (($last, $first, $index, $hc) = $_ =~ /^(\S+)\054\s*(\S+)\s+(\d+\056\d+)N\s+\/\s+(\d+)/) {
		$pn = $last . ", " . $first;
		printf("%-17s %4.1fN / %d\n", $pn, $index, $hc);
	    }
	}
    }
    close(FD);
}
