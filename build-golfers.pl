#! /usr/bin/perl

$fn = "Golfers.SK";
$out = "tnfb.pl";

open(FD, $fn);
open(NFD, ">", $out); 

print NFD "%golfers = (\n";

while ($line = <FD>) {

	if ($line =~ /^0,"\d\d\d\056ID/) {
		$line =~ s/["]//g;
		$line =~ s/,/:/g;

		@new = split(/:/, $line);
		$new[1] =~ s/^\s+|\s+$//g;
		$new[2] =~ s/^\s+|\s+$//g;
		$new[3] =~ s/^\s+|\s+$//g;
		$new[4] =~ s/^\s+|\s+$//g;
		print NFD "\t\"golfers/$new[1]\" => { first => \"$new[3]\", last => \"$new[2]\", team => \"$new[4]\" },\n";
	}
}

print NFD ");\n";

close(FD);
close(NFD);
