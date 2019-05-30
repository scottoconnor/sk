#! /usr/bin/perl
#
# Copyright (c) 2019, Scott O'Connor
#

use Getopt::Long;

$cur_year = (1900 + (localtime)[5]);
$start_year = 2003;

GetOptions (
	"w" => \$weekly_stats,
	"c" => \$cumulative_stats,
	"y=i" => \$start_year,
	"a" => \$all_time)
or die("Error in command line arguments\n");

undef (%y);

$num_weeks = 0;

#
# First, find how many weeks have been played in the current year.
#
for ($year = $cur_year; $year <= $cur_year; $year++) {
    for ($week = 1; $week <= 15; $week++) {
	$ret = `./skperf.pl -s -sy $year -ey $year -sw $week -ew $week | grep "Total holes played"`;
	($ret) = $ret =~ /Total holes played: (\d+)/;
	if ($ret > 0) {
	    $num_weeks++;
	}
    }
}

$week = $num_weeks;

for ($year = $start_year; $year <= $cur_year; $year++) {


    if ($all_time) {
    	@return = `./skperf.pl -s -sy $year -ey $year`;
	while ($line = shift @return) {
	    chomp ($line);
	    if (($ft) = $line =~ /50\053 = (\d+)/) {
		$y{$year}{ft} = $ft;
	    }
	    if (($thirty) = $line =~ /30\047s = (\d+)/) {
		defined($y{$year}{thirty} = $thirty);
	    }
	    if (($to) = $line =~ /Total Others = (\d+)/) {
		$y{$year}{to} = $to;
	    }
	    if (($tbo) = $line =~ /Total Bogies = (\d+)/) {
		$y{$year}{tbo} = $tbo;
	    }
	    if (($tp) = $line =~ /Total Pars = (\d+)/) {
		$y{$year}{tp} = $tp;
	    }
	    if (($tb) = $line =~ /Total Birdies = (\d+)/) {
		$y{$year}{tb} = $tb;
	    }
	    if (($te) = $line =~ /Total Eagles = (\d+)/) {
		$y{$year}{te} = $te;
	    }
	    if (($lsa) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
		$y{$year}{lsa} = $lsa;
	    }
	    if (($th) = $line =~ /Total holes played: (\d+)/) {
		$y{$year}{th} = $th;
	    }
	    if (($tposted) = $line =~ /Total Posted scores: (\d+)/) {
		$y{$year}{tposted} = $tposted;
	    }
	}
    }

    if ($weekly_stats) {
	#
	# Weekly stats now
	#

        @return = `./skperf.pl -s -sy $year -ey $year -sw $week -ew $week`;
	while ($line = shift @return) {
	    chomp ($line);
	    if (($wft) = $line =~ /50\053 = (\d+)/) {
		$y{$year}{wft} = $wft;
	    }
	    if (($thirty) = $line =~ /Total 30\047s = (\d+)/) {
		defined($y{$year}{wthirty} = $thirty);
	    }
	    if (($wlsa) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
		$y{$year}{wlsa} = $wlsa;
	    }
	    if (($two) = $line =~ /Total Others = (\d+)/) {
		$y{$year}{two} = $two;
	    }
	    if (($twbo) = $line =~ /Total Bogies = (\d+)/) {
		$y{$year}{twbo} = $twbo;
	    }
	    if (($twp) = $line =~ /Total Pars = (\d+)/) {
		$y{$year}{twp} = $twp;
	    }
	    if (($twb) = $line =~ /Total Birdies = (\d+)/) {
		$y{$year}{twb} = $twb;
	    }
	    if (($twe) = $line =~ /Total Eagles = (\d+)/) {
		$y{$year}{twe} = $twe;
	    }
	    if (($twh) = $line =~ /Total holes played: (\d+)/) {
		$y{$year}{twh} = $twh;
	    }
	    if (($twposted) = $line =~ /Total Posted scores: (\d+)/) {
		$y{$year}{twposted} = $twposted;
	    }
	}
    }

    if ($cumulative_stats) {
        @return = `./skperf.pl -s -sy $year -ey $year -sw 1 -ew $week`;
	while ($line = shift @return) {
	    chomp ($line);
	    if (($cft) = $line =~ /50\053 = (\d+)/) {
		$y{$year}{cft} = $cft;
	    }
	    if (($thirty) = $line =~ /Total 30\047s = (\d+)/) {
		defined($y{$year}{cthirty} = $thirty);
	    }
	    if (($clsa) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
		$y{$year}{clsa} = $clsa;
	    }
	    if (($cto) = $line =~ /Total Others = (\d+)/) {
		$y{$year}{cto} = $cto;
	    }
	    if (($ctbo) = $line =~ /Total Bogies = (\d+)/) {
		$y{$year}{ctbo} = $ctbo;
	    }
	    if (($ctp) = $line =~ /Total Pars = (\d+)/) {
		$y{$year}{ctp} = $ctp;
	    }
	    if (($ctb) = $line =~ /Total Birdies = (\d+)/) {
		$y{$year}{ctb} = $ctb;
	    }
	    if (($cte) = $line =~ /Total Eagles = (\d+)/) {
		$y{$year}{cte} = $cte;
	    }
	    if (($cth) = $line =~ /Total holes played: (\d+)/) {
		$y{$year}{cth} = $cth;
	    }
	    if (($tcuposted) = $line =~ /Total Posted scores: (\d+)/) {
		$y{$year}{tcuposted} = $tcuposted;
	    }
	}
    }
}

if ($weekly_stats) {

    print "\nLeague Stroke Average on week $week.\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{wlsa} <=> $y{$b}{wlsa} } (keys(%y))) {
	printf("%2d: %d -> %.2f\n", $cnt++, $xx, $y{$xx}{wlsa});
    }
    print "\nScores in 30's on week $week.\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{wthirty} <=> $y{$b}{wthirty} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{wthirty}, (($y{$xx}{wthirty} / $y{$xx}{twposted}) * 100));
    }
    print "\n50+ on week $week.\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{wft} <=> $y{$b}{wft} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{wft}, (($y{$xx}{wft} / $y{$xx}{twposted}) * 100));
    }
    print "\nOthers on week $week.\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{two} <=> $y{$b}{two} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{two}, (($y{$xx}{two} / $y{$xx}{twh}) * 100));
    }
    print "\nBogies on week $week.\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{twbo} <=> $y{$b}{twbo} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twbo}, (($y{$xx}{twbo} / $y{$xx}{twh}) * 100));
    }
    print "\nPars on week $week.\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{twp} <=> $y{$b}{twp} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twp}, (($y{$xx}{twp} / $y{$xx}{twh}) * 100));
    }
    print "\nBirdies on week $week.\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{twb} <=> $y{$b}{twb} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twb}, (($y{$xx}{twb} / $y{$xx}{twh}) * 100));
    }
    print "\nEagles on week $week.\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{twe} <=> $y{$b}{twe} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twe}, (($y{$xx}{twe} / $y{$xx}{twh}) * 100));
    }
}

if ($cumulative_stats) {

    print "\nLeague Stroke Average. Week 1 through $week\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{clsa} <=> $y{$b}{clsa} } (keys(%y))) {
	printf("%2d: %d -> %.2f\n", $cnt++, $xx, $y{$xx}{clsa});
    }
    print "\nScores in 30's. Week 1 through $week.\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{cthirty} <=> $y{$b}{cthirty} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cthirty}, (($y{$xx}{cthirty} / $y{$xx}{tcuposted}) * 100));
    }
    print "\nScores of 50+. Week 1 through $week\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{cft} <=> $y{$b}{cft} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cft}, (($y{$xx}{cft} / $y{$xx}{tcuposted}) * 100));
    }
    print "\nOthers. Week 1 through $week\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{cto} <=> $y{$b}{cto} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cto}, (($y{$xx}{cto} / $y{$xx}{cth}) * 100));
    }
    print "\nBogies. Week 1 through $week\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{ctbo} <=> $y{$b}{ctbo} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ctbo}, (($y{$xx}{ctbo} / $y{$xx}{cth}) * 100));
    }
    print "\nPars. Week 1 throught $week\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{ctp} <=> $y{$b}{ctp} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ctp}, (($y{$xx}{ctp} / $y{$xx}{cth}) * 100));
    }
    print "\nBirdies. Week 1 through $week\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{ctb} <=> $y{$b}{ctb} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ctb}, (($y{$xx}{ctb} / $y{$xx}{cth}) * 100));
    }
    print "\nEagles. Week 1 through $week\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{cte} <=> $y{$b}{cte} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cte}, (($y{$xx}{cte} / $y{$xx}{cth}) * 100));
    }
}

if ($all_time) {

    print "\nAll time League Stroke Average.\n";
    $cnt = 1;
    foreach $xx (sort { $y{$a}{lsa} <=> $y{$b}{lsa} } (keys(%y))) {
	printf("%2d: %d -> %.2f\n", $cnt++, $xx, $y{$xx}{lsa});
    }
    print "\nAll time scores in 30's.\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{thirty} <=> $y{$b}{thirty} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{thirty}, (($y{$xx}{thirty} / $y{$xx}{tposted}) * 100));
    }
    print "\nAll time 50+.\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{ft} <=> $y{$b}{ft} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ft}, (($y{$xx}{ft} / $y{$xx}{tposted}) * 100));
    }
    print "\nAll time Others\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{to} <=> $y{$b}{to} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{to}, (($y{$xx}{to} / $y{$xx}{th}) * 100));
    }
    print "\nAll Time Bogies\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{tbo} <=> $y{$b}{tbo} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{tbo}, (($y{$xx}{tbo} / $y{$xx}{th}) * 100));
    }
    print "\nAll Time Pars\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{tp} <=> $y{$b}{tp} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{tp}, (($y{$xx}{tp} / $y{$xx}{th}) * 100));
    }
    print "\nAll Time Birdies\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{tb} <=> $y{$b}{tb} } (keys(%y))) {
	printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{tb}, (($y{$xx}{tb} / $y{$xx}{th}) * 100));
    }
    print "\nAll Time Eagles\n";
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{te} <=> $y{$b}{te} } (keys(%y))) {
	printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{te}, (($y{$xx}{te} / $y{$xx}{th}) * 100));
    }
}
