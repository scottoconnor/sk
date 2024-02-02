#! /usr/bin/perl
#
# Copyright (c) 2024, Scott O'Connor
#
# This is a random generator for the week 16 (blind draw) point quota tournament.
#

use Crypt::Random::Seed;
use Time::HiRes qw(gettimeofday);

%golfers = (
    1 =>  { name => "Dan Correia", taken => 0 , partner => 2 },
    2 =>  { name => "Paul Correia", taken => 0, partner => 1 },
    3 =>  { name => "Chet Czapkowski", taken => 0, partner =>  4 },
    4 =>  { name => "Jim Marotta", taken => 0, partner => 3 },
    5 =>  { name => "Scott O'Connor", taken => 0, partner => 6 },
    6 =>  { name => "Paul Percuoco", taken => 0, partner => 5 },
    7 =>  { name => "Pat Donahue", taken => 0, partner => 8 },
    8 =>  { name => "Joe Sullivan", taken => 0, partner => 7 },
    9 =>  { name => "Mike Rogers", taken => 0, partner => 10 },
    10 => { name => "John Maley", taken => 0, partner =>  9 },
    11 => { name => "Tom Curley", taken => 0, partner =>  12 },
    12 => { name => "Ray Curley", taken => 0, partner => 11 },
    13 => { name => "Kevin Cunningham", taken => 0, partner => 14 },
    14 => { name => "Mike Perisho", taken => 0, partner => 13},
    15 => { name => "Randy Carter", taken => 0, partner => 16 },
    16 => { name => "Jim O'Keefe", taken => 0, partner => 15},
    17 => { name => "Bobby Kilgus", taken => 0, partner => 18 },
    18 => { name => "Derek Jodoin", taken => 0, partner => 17 },
    19 => { name => "Mike Gill", taken => 0, partner => 20 },
    20 => { name => "Marc Foland", taken => 0, partner => 19 },
    21 => { name => "Tony Albertini", taken => 0, partner => 22 },
    22 => { name => "Kevin Kittredge", taken => 0, partner => 21 },
    23 => { name => "Pete Linstrom", taken => 0, partner => 24 },
    24 => { name => "Paul Sirois", taken => 0, partner => 23 },
    25 => { name => "John Breslouf", taken => 0, partner => 26 },
    26 => { name => "Steve Bulawka", taken => 0, partner => 25 },
    27 => { name => "Bob Tuttle", taken => 0, partner => 28 },
    28 => { name => "Jeff Miller", taken => 0, partner => 27 },
    29 => { name => "Charlie Weeks", taken => 0, partner => 30 },
    30 => { name => "Mike Schmidt", taken => 0, partner => 29},
    31 => { name => "Charlie Bacon", taken => 0, partner => 32 },
    32 => { name => "Larry Fryatt", taken => 0, partner => 31 },
);

my $source = new Crypt::Random::Seed;
die "No strong sources exist" unless defined $source;

$lastx = 0;
$filename = "week16";

unlink $filename, if (-e $filename);

$y = 1;

while ($y < 33) {
    $which_num = (int(rand(4)));
    @seed_values = $source->random_values(4); 
    print "@seed_values\n", if 0;
    $seed = $seed_values[$which_num];
    print STDOUT "seed -> $seed - which_num = $which_num\n", if 0;
    srand($seed);

    $x = int(rand(32));
    $x += 1;

    next, if ($golfers{$x}{taken});

    if ($golfers{$x}{partner} == $lastx) {
        #
        # Dead lock. The last golfer picked will be paried
        # with their league partner. Start over.
        #
        if ($y == 32) {
            foreach $p (sort keys %golfers) {
                $golfers{$p}{taken} = 0;
            }
            $y = 1;
            $lastx = 0;
        }
        next;
    } 

    $golfers{$x}{taken} = 1;
    $team{$y} = $golfers{$x}{name};

    if ($y % 2) {
        $lastx = $x;
    } else {
        $lastx = 0;
    }
    sleep(int(rand(4))), if 0;
    $y++;
}

open(FD, ">", $filename);
$y = 1;
while ($y < 33) {
    print FD "$team{$y}\n";
    print STDOUT "$team{$y}\n";
    print FD "\n", if (($y & 1) == 0 && $y != 32);
    print STDOUT "\n", if (($y & 1) == 0 && $y != 32);
    $y++;
}
close(FD);
