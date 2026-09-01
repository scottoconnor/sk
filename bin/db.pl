#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use Getopt::Long qw(:config no_ignore_case);
use GDBM_File;

use FindBin;
use lib "$FindBin::Bin/..";

require 'hcroutines.pl';

my (%golfers_gdbm, %tnfb_db, $file, $dh, $pn);

my ($modify) = 0;
my ($delete) = 0;
my ($add) = 0;
my ($create) = 0;
my ($view) = 0;
my ($search_key) = 0;
my ($search_del_key) = 0;
my ($search_value) = 0;
my ($end_year) = (1900 + (localtime)[5]);
my ($path) = "/home/soconnor/sk/golfers";
#my ($path) = "/home/soconnor/backup";
my ($file_path);
our (%dates);

GetOptions (
    "a" => \$add,
    "c" => \$create,
    "d" => \$delete,
    "m" => \$modify,
    "s" => \$search_key,
    "sd" => \$search_del_key,
    "S" => \$search_value,
    "v" => \$view)
or die("Error in command line arguments\n");

if ($modify == 0 && $delete == 0 && $add == 0 && $view == 0 && $search_key == 0
    && $search_del_key == 0 && $search_value == 0 && $create == 0) {
    die "usage: db.pl [options] \
Options: \
  -a         Add a new key/value entry into a player's scoring record. \
  -c         Create a new player tnfb database. \
  -d         Delete a key/value in a player's scoring record. \
  -m         Modify a value of an existing key in the player's scoring record. \
  -s         Search all player's scoring record for a key. \
  -sd        Search all player's scoring record for a key and delete it. \
  -S         Search all player's scoring record for a value. \
  -v         View the player's entire database record.\n";
}

&get_years_weeks_dates();

opendir($dh, $path) || die "Can't open directory.";

while (readdir $dh) {
    if ($_ =~ /(^1\d{3}$\.gdbm)/) {
        $file_path = "$path/$_";
        tie %tnfb_db, 'GDBM_File', $file_path, GDBM_READER, 0644
            or die "$GDBM_File::gdbm_errno";
        print "$tnfb_db{'Player'} - $file_path\n", if 0;
        $golfers_gdbm{$tnfb_db{'Player'}} = $file_path;
        untie %tnfb_db;
    }
}
closedir ($dh);

if ($modify == 1 || $delete == 1 || $add == 1 || $view == 1) {
    print "Enter Player name: ";
    chomp($pn = <STDIN>);
    if (!exists($golfers_gdbm{$pn})) {
        die "$pn does not exists.\n";
    }
    $file = $golfers_gdbm{$pn};
    #print "$pn: $file\n";
}

if ($add) {
    add_key($file);
}

if ($create) {
    create_tnfb_db();
}

if ($delete) {
    delete_key($file);
}

if ($modify) {
    modify_key($file);
}

if ($search_key) {
    search_db_key();
}

if ($search_del_key) {
    search_del_db_key();
}

if ($search_value) {
    search_db_value();
}

if ($view) {
    view_db($file);
}

sub
add_key {
    my ($file) = @_;
    my ($new_val, $key);

    tie %tnfb_db, 'GDBM_File', $file, GDBM_WRITER, 0644
        or die "$GDBM_File::gdbm_errno";

    print "Enter key to add: ";
    chomp($key = <STDIN>);

    print "Enter value for $key: ";
    chomp($new_val = <STDIN>);

    if (exists($tnfb_db{$key})) {
        print "$pn: $key already exists with value $tnfb_db{$key}.\n";
    } else {
        print "$pn: Adding new key \"$key\" with value $new_val\n";
        $tnfb_db{$key} = $new_val;
    }
    untie %tnfb_db;
}

sub
create_tnfb_db {
    my ($new_pn) = @_;
    my ($new_file, $x, $y, $hi);

    for ($x = 1; $x < 300; $x++) {
        $y = 1000 + $x;
        $new_file = "golfers/$y.gdbm";
        if (! -e $new_file) {
            print "new db file is: $new_file\n";
            last;
        }
    }

    tie %tnfb_db, 'GDBM_File', $new_file, GDBM_WRCREAT, 0644
        or die "$GDBM_File::gdbm_errno";
    
    print "Enter Player's name: ";
    chomp($new_pn = <STDIN>);
    $tnfb_db{'Player'} = $new_pn;
    $tnfb_db{'Team'} = "Sub";
    $tnfb_db{'Active'} = 1;
    print "Enter $new_pn\'s Handicap Index: ";
    chomp($hi = <STDIN>);
    $tnfb_db{'Current'} = $hi;
    untie %tnfb_db;

    #
    # Update golfers_gdbm hash
    #
    $golfers_gdbm{$new_pn} = $new_file;
}

#
# Allow for multiple keys to be deleted. A missing key will stop the loop
#
sub
delete_key {
    my ($file) = @_;
    my $key;
    my $continue = 1;

    tie %tnfb_db, 'GDBM_File', $file, GDBM_WRITER, 0644
        or die "$GDBM_File::gdbm_errno";

    while ($continue) {
        print "Enter key to delete: ";
        chomp($key = <STDIN>);

        if (exists($tnfb_db{$key})) {
            print "Deleting \"$key: $tnfb_db{$key}\" from $pn\n";
            delete($tnfb_db{$key});
        } else {
            print "$key does not exists .... stopping.\n";
            $continue = 0;
        }

    }

    untie %tnfb_db;
}

sub
modify_key {
    my ($file) = @_;
    my ($new_val, $key);

    tie %tnfb_db, 'GDBM_File', $file, GDBM_WRITER, 0644
        or die "$GDBM_File::gdbm_errno";

    while (1) {
        print "Enter key to Change: ";
        chomp($key = <STDIN>);

        if (!exists($tnfb_db{$key})) {
            print "\"$key\" does not exists.\n";
            untie %tnfb_db;
            return;
        }

        print "current vaule of $key is: $tnfb_db{$key}\n";
        print "New value for $key: ";
        chomp($new_val = <STDIN>);
        print "Changing $tnfb_db{$key} to $new_val\n";
        $tnfb_db{$key} = $new_val;
    }

    untie %tnfb_db;
}

sub
search_db_key {

    my ($count) = 0;
    print "Enter key to find: ";
    chomp(my $key = <STDIN>);

    foreach my $pn (sort keys %golfers_gdbm) {
        my $file = $golfers_gdbm{$pn};

        tie %tnfb_db, 'GDBM_File', $file, GDBM_WRITER, 0640
            or die "$GDBM_File::gdbm_errno";

        if (exists($tnfb_db{$key})) {
            printf "%-17s: %s\n", $tnfb_db{'Player'}, $tnfb_db{$key};
            #my $sr = $tnfb_db{$key};
            #if ($sr =~ /1997-8-21/) {

                #$sr =~ s/1997-8-21/1997-8-19/;
                #my $correct_date = "1997-8-19";
                #printf "%-17s: %s\n", $tnfb_db{'Player'}, $sr;

                #$tnfb_db{$correct_date} = $sr;
            #}
            $count++
        }
        untie %tnfb_db;
    }
    print "Found $count entries\n";
}

sub
search_del_db_key {

    my ($count) = 0;
    print "Enter key to find and delete: ";
    chomp(my $key = <STDIN>);

    foreach my $pn (sort keys %golfers_gdbm) {
        my $file = $golfers_gdbm{$pn};

        tie %tnfb_db, 'GDBM_File', $file, GDBM_WRITER, 0644
            or die "$GDBM_File::gdbm_errno";

        if (exists($tnfb_db{$key})) {
            delete($tnfb_db{$key});
            $count++
        }
        untie %tnfb_db;
    }
    print "Deleted $count keys = $key.\n";
}

sub
search_db_value {

    print "Enter value to find: ";
    chomp(my $value = <STDIN>);

    foreach my $pn (sort keys %golfers_gdbm) {
        my $file = $golfers_gdbm{$pn};

        tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0640
            or die "$GDBM_File::gdbm_errno";

        $pn = $tnfb_db{'Player'};

        while (my($key, $val) = each %tnfb_db) {
            if ($val =~ /$value/) {
                print "$pn: $key: $val\n";
            }
        }
        untie %tnfb_db;
    }
}

sub
view_db {
    my ($file) = @_;

    tie %tnfb_db, 'GDBM_File', $file, GDBM_READER, 0640
        or die "$GDBM_File::gdbm_errno";

    my ($y, $m, $d, $team, $w, $da, $found);
    my ($scores) = 0;

    foreach $y (1997..$end_year) {
        $team = "Team_$y";
        if (exists($tnfb_db{$team})) {
            print "$team: $tnfb_db{$team}\n";
        }
        foreach $m (1..12) {
            foreach $d (1..31) {
                my $date = "$y-$m-$d";
                if (exists($tnfb_db{$date})) {
                    $found = 1;
                    for ($w = 1; $w < 16; $w++) {
                        $da = $dates{$y}{$w};
                        if ($da eq $date) {
                            $found = 1;
                        }
                    }
                    if (!$found && $y > 2002) {
                        untie %tnfb_db;
                        die "\tBAD: da: $da, date(bad): $date\n";
                    }
                    print "$date: $tnfb_db{$date}\n";
                    $scores++;
                }
            }
        }
    }

    print "Name: $tnfb_db{'Player'}\n";
    if (exists($tnfb_db{'Team'})) {
        print "Team: $tnfb_db{'Team'}\n";
    }
    if (exists($tnfb_db{'Active'})) {
        print "Active: $tnfb_db{'Active'}\n";
    }
    if (exists($tnfb_db{'Current'})) {
        printf "Current: %.1f\n", $tnfb_db{'Current'};
    }
    if (exists($tnfb_db{'new_hi'})) {
        printf "new_hi: %.1f\n", $tnfb_db{'new_hi'};
    }
    print "db file: $file\n";
    print "Number of scores: $scores\n";

    untie %tnfb_db;
}
