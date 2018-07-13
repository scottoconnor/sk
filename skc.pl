#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require 'courses.pl';

for ($cnt = 1; $cnt < 130; $cnt++) {
	if ($cnt < 10) {
		$fna = "00$cnt" . ".ID";
		$ofna = "00$cnt" . ".OUT";
	} elsif ($cnt >= 10 && $cnt < 100) {
		$fna = "0$cnt" . ".ID";
		$ofna = "0$cnt" . ".OUT";
	} elsif ($cnt == 100) {
		$fna = "$cnt" . ".ID";
		$ofna = "$cnt" . ".OUT";
	} elsif ($cnt > 100) {
		$fna = "subs/" . "$cnt" . ".ID";
		$ofna = "subs/" . "$cnt" . ".OUT";
	}

	if (-e $fna) {
		print "fna = $fna\n";
	} else {
		next;
	}

	open (FD, "$fna");
	open (OFD, ">", "$ofna");

	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;
	$_ = <FD>;
	print OFD;

	while (<FD>) {
		if ($_ =~ /South Front/) {
			($par, $slope, $course) = split(/,/);
			$par = $c{SF}{par};
			$slope = $c{SF}{slope};
			print OFD "$par,$slope,$course";
		} elsif ($_ =~ /South Back/) {
			($par, $slope, $course) = split(/,/);
			$par = $c{SB}{par};
			$slope = $c{SB}{slope};
			print OFD "$par,$slope,$course";
		} elsif ($_ =~ /North Front/) {
			($par, $slope, $course) = split(/,/);
			$par = $c{NF}{par};
			$slope = $c{NF}{slope};
			print OFD "$par,$slope,$course";
		} elsif ($_ =~ /North Back/) {
			($par, $slope, $course) = split(/,/);
			$par = $c{NB}{par};
			$slope = $c{NB}{slope};
			print OFD "$par,$slope,$course";
		} else {
			print OFD;
		}
	}
	
	close (FD);
	close (OFD);
	unlink $fna;
	rename ($ofna, $fna);
}
