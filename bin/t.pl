#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use warnings;
use GDBM_File;

my $path = "/home/soconnor/sk/golfers/";

print "Enter database number of player: ";
my $db_num = <STDIN>;
chomp($db_num);
my $filename = $path . $db_num . ".gdbm";

# Tie the GDBM file to a normal perl hash in read-only mode (GDBM_READER)
tie my %hash, 'GDBM_File', $filename, GDBM_READER, 0444
    or die "Cannot open $filename: $!";

# Loop through all keys and values in the GDBM file
while (my ($key, $value) = each %hash) {
    print "$key => $value\n";
}

print "$hash{'Player'}\n";

untie %hash;
