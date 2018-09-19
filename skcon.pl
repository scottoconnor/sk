#! /usr/bin/perl
#
# Copyright (c) 2018 Scott O'Connor
#

require 'tnfb.pl';
require 'courses.pl';

for ($cnt = 1, $xx = 200; $cnt < 200; $cnt++, $xx++) {
	if ($cnt < 10) {
		$fna = "golfers/" . "00$cnt" . ".ID"
	} elsif ($cnt >= 10 && $cnt < 100) {
		$fna = "golfers/" ."0$cnt" . ".ID";
	} elsif ($cnt == 100) {
		$fna = "golfers/" ."$cnt" . ".ID";
	} elsif ($cnt > 100) {
		$fna = "golfers/" . "$cnt" . ".ID";
	}

	if (-e $fna) {
		print "fna = $fna\n";
		&player_stat($fna, "golfers/$xx");
	}
}

sub player_stat {

my($fn, $fnnew) = @_;

$debug = 0;

open(FD, $fn);
open(NFD, ">", $fnnew); 

# First line is the ScoreKeeper tag, throw them away
# to get to the players name.
$line = <FD>;

$line = <FD>;
($last, $first) = $line =~ /\042(.+)\054\s(.+)\042/;

if (defined($golfers{$fn})) {
	print NFD "$first:$last:$golfers{$fn}->{team}\n";
} else {
	print NFD "$first:$last:Sub\n";
}

$line = <FD>;
$line = <FD>;
$line = <FD>;
$line = <FD>;
$line = <FD>;
$line = <FD>;
$line = <FD>;

while ($line = <FD>) {

	undef $course;
	$shot = 0;

	if ($line =~ /^\d{6,7}\054/) {
		print "$line", if $debug;
		$num = @fields = split(',', $line);
		if ($num == 7) {
			$date = @fields[0];
			$shot = @fields[3];
			$post = @fields[5];
		} elsif ($num == 8) {
			$date = @fields[0];
			$shot = @fields[4];
			$post = @fields[6];
		} else {
			print "Error on getting date, shot, post!!!\n";
		}

		if ($line =~ /^9\d{5}/) {
			($year, $month, $day) = $line =~ /(9\d)(\d\d)(\d\d)/;
			$year = "19" . $year;
			$month = abs($month);
			$day = abs($day);
			print "Date = $date - $year, $month, $day - $shot - $post\n", if $debug;
		} elsif ($line =~ /^1\d{6}/) {
			($year, $month, $day) = $line =~ /^1(\d\d)(\d\d)(\d\d)/;
			$year = "20" . $year;
			$month = abs($month);
			$day = abs($day);
			print "Date = $date - $year, $month, $day - $shot - $post\n", if $debug;
		} else {
			print "Not found!\n";
		}
	}

	$line = <FD>;

	($par, $slope, $course) = $line =~ /^(\d\d\056{0,1}\d{0,1})\054(\d{2,3})\054\042(.+)\042/;
	print "$course: $par $slope\n", if $debug;

	if ($course =~ /Stow\/South Front/) {
		$course = 'SF';
		$par = $c{$course}{par};
		$slope = $c{$course}{slope};
	} elsif ($course =~ /Stow\/South Back/) {
		$course = 'SB';
		$par = $c{$course}{par};
		$slope = $c{$course}{slope};
	} elsif ($course =~ /Stow\/North Front/) {
		$course = 'NF';
		$par = $c{$course}{par};
		$slope = $c{$course}{slope};
	} elsif ($course =~ /Stow\/North Back/) {
		$course = 'NB';
		$par = $c{$course}{par};
		$slope = $c{$course}{slope};
	} else {
		$course = 'NL';
		#$line = <FD>;
		#$line = <FD>;
		#$line = <FD>;
		#$line = <FD>;
		#$line = <FD>;
		#next;
	}

	$line = <FD>;
	$line = <FD>;

	$stlen = length($line);
	$stlen -= 2;
	$line = substr($line, 0, $stlen);

	$check_shot = 0;

	if ($line =~ /^\d{9}\0540/) {

		print NFD "$course:$par:$slope:$year-$month-$day:$shot:$post";

                ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                        /^(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)/;

		$count = 1;
		while (defined($v = shift(@a))) {
			$v = abs($v);
			if ($v == 0) { $v = 10 };
			if ($v == 1 && $c{$course}->{$count} > 3) { $v = 11 };
			print NFD ":$v";
			$check_shot += $v;
			$count++;
                }
                print NFD "\n";

                if ($check_shot != $shot) {
                        print "9: $fn: $shot: $check_shot, Incorrect! -- $line\n";
                }
	} elsif ($line =~ /^\d{8}\0540/) {

		print NFD "$course:$par:$slope:$year-$month-$day:$shot:$post";

                ($a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                        /^(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)/;
		$a[0] = 10;

		$count = 1;
		while (defined($v = shift(@a))) {
			$v = abs($v);
			if ($v == 0) { $v = 10 };
			if ($v == 1 && $c{$course}->{$count} > 3) { $v = 11 };
			print NFD ":$v";
			$check_shot += $v;
			$count++;
                }
                print NFD "\n";

                if ($check_shot != $shot) {
                        print "8: $fn: $shot: $check_shot, Incorrect! -- $line\n";
                }
	} elsif ($line =~ /^\d{13}\056\d{3}\054/) {

		#
		# A 13,3 format is a score with a 10 on the last hole.
		#

		print NFD "$course:$par:$slope:$year-$month-$day:$shot:$post";

                ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                        /^(\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)\056(\d\d)(\d)\054/;

		$a[8] = 10;  # in this format

		while (defined($v = shift(@a))) {
			$v = abs($v);
			print NFD ":$v";
			$check_shot += $v;
                }
                print NFD "\n";

                if ($check_shot != $shot) {
                        print "13,3: $shot: $check_shot, Incorrect!\n";
                }
	} elsif ($line =~ /^\d{13}\056\d{4}\054/) {

		print NFD "$course:$par:$slope:$year-$month-$day:$shot:$post";

                ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                        /^(\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)\056(\d\d)(\d\d)\054/;

		while (defined($v = shift(@a))) {
			$v = abs($v);
			print NFD ":$v";
			$check_shot += $v;
                }
                print NFD "\n";

                if ($check_shot != $shot) {
			print "13,4: $fn $line $shot: $check_shot. (Issue)\n";
                }
	} elsif ($line =~ /^\d{14}\056\d{3}\054/) {
		#
		# A 14,3 format is a score with big number on hole #1 and a 10 on the last hole.
		#

		print NFD "$course:$par:$slope:$year-$month-$day:$shot:$post";

                ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                        /^(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)\056(\d\d)(\d)\054/;

		$a[8] = 10;  # in this format

		while (defined($v = shift(@a))) {
			$v = abs($v);
			print NFD ":$v";
			$check_shot += $v;
                }
                print NFD "\n";

		print "13,3: $fn $line $shot: $check_shot.\n", if $debug;
                if ($check_shot != $shot) {
                        print "13,3: $shot: $check_shot, Incorrect!\n";
                }
	} elsif ($line =~ /^\d{14}\056\d{4}\054/) {
		#
		# Lines with score in the format 14.4,0 have scores that hole number 1 is
		# a 10 or higher.
		#

		print NFD "$course:$par:$slope:$year-$month-$day:$shot:$post";

                ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                        /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d{2})\054/;

		while (defined($v = shift(@a))) {
			$v = abs($v);
			print NFD ":$v";
			$check_shot += $v;
                }
                print NFD "\n";

                if ($check_shot != $shot) {
			print "14,4: $fn, $shot: $check_shot, $line Issue!\n";
		}
	} elsif ($line =~ /^0\0540/) {
		print NFD "$course:$par:$slope:$year-$month-$day:$shot:$post\n";
	} else {
		print "Unexpected line: $fn: $line -- $course\n"
	}

	$line = <FD>;
	$line = <FD>;
	$line = <FD>;
}

close(FD);
close (NFD);
}
