#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require 'courses.pl';

opendir($dh, "./golfers") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ =~ /^\d+\056ID/) {
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
			if ($par != $c{SF}{par}) {
				print "$fna:  fixing SF par.\n";
				$par = $c{SF}{par};
			}
			if ($slope != $c{SF}{slope}) {
				print "$fna:  fixing SF slope.\n";
				$slope = $c{SF}{slope};
			}
			print OFD "$par,$slope,$course";
		} elsif ($_ =~ /South Back/) {
			($par, $slope, $course) = split(/,/);
			if ($par != $c{SB}{par}) {
				print "$fna:  fixing SB par.\n";
				$par = $c{SB}{par};
			}
			if ($slope != $c{SB}{slope}) {
				print "$fna:  fixing SB slope.\n";
				$slope = $c{SB}{slope};
			}
			print OFD "$par,$slope,$course";
		} elsif ($_ =~ /North Front/) {
			($par, $slope, $course) = split(/,/);
			if ($par != $c{NF}{par}) {
				print "$fna:  fixing NF par.\n";
				$par = $c{NF}{par};
			}
			if ($slope != $c{NF}{slope}) {
				print "$fna:  fixing NF slope.\n";
				$slope = $c{NF}{slope};
			}
			print OFD "$par,$slope,$course";
		} elsif ($_ =~ /North Back/) {
			($par, $slope, $course) = split(/,/);
			if ($par != $c{NB}{par}) {
				print "$fna:  fixing NB par.\n";
				$par = $c{NB}{par};
			}
			if ($slope != $c{NB}{slope}) {
				print "$fna:  fixing NB slope.\n";
				$slope = $c{NB}{slope};
			}
			print OFD "$par,$slope,$course";
		} else {
			print OFD;
		}
	}
	
	close (FD);
	close (OFD);
	#unlink $fna;
	#rename ($ofna, $fna);
}
