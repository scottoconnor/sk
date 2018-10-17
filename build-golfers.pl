#! /usr/bin/perl

$fn = "Golfers.SK";
$out = "tnfb.pl";

open(FD, $fn);
open(NFD, ">", $out); 

print NFD "%golfers = (\n";

while ($line = <FD>) {

	if ($line =~ /^"\d\d\d\056ID/) {
		$line =~ s/["]//g;
		$line =~ s/,/:/g;

		@new = split(/:/, $line);
		$new[0] =~ s/^\s+|\s+$//g;
		$new[1] =~ s/^\s+|\s+$//g;
		$new[2] =~ s/^\s+|\s+$//g;
		$new[3] =~ s/^\s+|\s+$//g;
		print NFD "\t\"golfers/$new[0]\" => { first => \"$new[2]\", last => \"$new[1]\", team => \"$new[3]\" },\n";
	}
}

print NFD ");\n";

close(FD);
close(NFD);
