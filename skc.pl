#! /usr/bin/perl
#
# Copyright (c) 2018, 2020 Scott O'Connor
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
			($course_rating, $slope, $course) = split(/,/);
			if ($course_rating != $c{SF}{course_rating}) {
				print "$fna:  fixing SF par rating.\n";
				$course_rating = $c{SF}{course_rating};
			}
			if ($slope != $c{SF}{slope}) {
				print "$fna:  fixing SF slope.\n";
				$slope = $c{SF}{slope};
			}
			print OFD "$course_rating,$slope,$course";
		} elsif ($_ =~ /South Back/) {
			($course_rating, $slope, $course) = split(/,/);
			if ($course_rating != $c{SB}{course_rating}) {
				print "$fna:  fixing SB par rating.\n";
				$course_rating = $c{SB}{course_rating};
			}
			if ($slope != $c{SB}{slope}) {
				print "$fna:  fixing SB slope.\n";
				$slope = $c{SB}{slope};
			}
			print OFD "$course_rating,$slope,$course";
		} elsif ($_ =~ /North Front/) {
			($course_rating, $slope, $course) = split(/,/);
			if ($course_rating != $c{NF}{course_rating}) {
				print "$fna:  fixing NF par rating.\n";
				$course_rating = $c{NF}{course_rating};
			}
			if ($slope != $c{NF}{slope}) {
				print "$fna:  fixing NF slope.\n";
				$slope = $c{NF}{slope};
			}
			print OFD "$course_rating,$slope,$course";
		} elsif ($_ =~ /North Back/) {
			($course_rating, $slope, $course) = split(/,/);
			if ($course_rating != $c{NB}{course_rating}) {
				print "$fna:  fixing NB par rating.\n";
				$course_rating = $c{NB}{course_rating};
			}
			if ($slope != $c{NB}{slope}) {
				print "$fna:  fixing NB slope.\n";
				$slope = $c{NB}{slope};
			}
			print OFD "$course_rating,$slope,$course";
		} else {
			print OFD;
		}
	}
	
	close (FD);
	close (OFD);
	#unlink $fna;
	#rename ($ofna, $fna);
}
