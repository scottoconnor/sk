#! /usr/bin/perl
#
# Copyright (c) 2018, 2019 Scott O'Connor
#

$fn = "Golfers.SK";
$out = "tnfb.pl";

open(FD, $fn);
open(NFD, ">", $out); 

print NFD "%t = (
    \"TNFB/East/Black Bears\"    => { 1 => \"Cunningham, Kevin\", 2 => \"Perisho, Mike\" },
    \"TNFB/East/Eagles\"         => { 1 => \"Correia, Paul\", 2 => \"Correia, Dan\" },
    \"TNFB/East/Huskies\"        => { 1 => \"Rogers, Mike\", 2 => \"Maley, John\" },
    \"TNFB/East/Minutemen\"      => { 1 => \"Curley, Tom\", 2 => \"Curley, Ray\" },
    \"TNFB/East/River Hawks\"    => { 1 => \"Czapkowski, Chet\", 2 => \"Marotta, Jim\" },
    \"TNFB/East/Terriers\"       => { 1 => \"O'Connor, Scott\", 2 => \"Treen, Phil\" },
    \"TNFB/East/Warriors\"       => { 1 => \"Donahue, Pat\", 2 => \"Sullivan, Joe\" },
    \"TNFB/East/Wildcats\"       => { 1 => \"Carter, Randy\", 2 => \"O'Keefe, Jim\" },
    \"TNFB/West/Badgers\"        => { 1 => \"Kilgus, Bob\", 2 => \"Jodoin, Derek\" },
    \"TNFB/West/Buckeyes\"       => { 1 => \"Bacon, Charlie\", 2 => \"Fryatt, Larry\" },
    \"TNFB/West/Bulldogs\"       => { 1 => \"Gill, Mike\", 2 => \"Foland, Marc\" },
    \"TNFB/West/Fighting Sioux\" => { 1 => \"Albertini, Tony\", 2 => \"Kittredge, Kevin\" },
    \"TNFB/West/Golden Gofers\"  => { 1 => \"Breslouf, John\", 2 => \"Bulawka, Steve\" },
    \"TNFB/West/Pioneers\"       => { 1 => \"Tuttle, Bob\", 2 => \"Miller, Jeff\" },
    \"TNFB/West/Seawolves\"      => { 1 => \"Weeks, Charlie\", 2 => \"Schmidt, Mike\" },
    \"TNFB/West/Tigers\"         => { 1 => \"Linstrom, Pete\", 2 => \"Sirois, Paul\" },
);
\n";

print NFD "%golfers = (\n";

while ($line = <FD>) {

    if ($line =~ /^0|-1,"\d+\056ID/) {
	$line =~ s/["]//g;

	@new = split(/,/, $line);
	$active = ($new[0] + 1);
	$new[1] =~ s/^\s+|\s+$//g;
	$new[2] =~ s/^\s+|\s+$//g;
	$new[3] =~ s/^\s+|\s+$//g;
	$new[4] =~ s/^\s+|\s+$//g;
	if ($new[4] =~ /TNFB/) {
	    print NFD "    \"golfers/$new[1]\" => { name => \"$new[3] $new[2]\", team => \"$new[4]\", active => $active },\n";
	}
    }
}

seek(FD, 0, SEEK_SET);

while ($line = <FD>) {

    if ($line =~ /^0|-1,"\d+\056ID/) {
	$line =~ s/["]//g;

	@new = split(/,/, $line);
	$active = ($new[0] + 1);
	$new[1] =~ s/^\s+|\s+$//g;
	$new[2] =~ s/^\s+|\s+$//g;
	$new[3] =~ s/^\s+|\s+$//g;
	$new[4] =~ s/^\s+|\s+$//g;
	if ($new[4] =~ /Sub/) {
	    print NFD "    \"golfers/$new[1]\" => { name => \"$new[3] $new[2]\", team => \"$new[4]\", active => $active },\n";
	}
    }
}

print NFD ");\n";

close(FD);
close(NFD);
