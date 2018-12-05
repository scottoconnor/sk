#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require 'courses.pl';

opendir($dh, "./golfers") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ =~ /\d+\056ID/) {
        push @golfer_list, $_;
    }
}
closedir ($dh);

@golfer_list = sort @golfer_list;

while ($fna = shift @golfer_list) {

	($num) = $fna =~ /(\d+)\056ID/;

	$ofna = "golfers/" . "$num" . ".OUT";
	$fna = "golfers/" . $fna;

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
