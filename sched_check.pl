#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

use strict;
use warnings;

my $east_teams = "Eagles|River Hawks|Terriers|Warriors|Huskies|Minutemen|Black Bears|Wildcats";
my $west_teams = "Badgers|Bulldogs|Fighting Sioux|Tigers|Golden Gophers|Pioneers|Seawolves|Buckeyes";
my $tnfb_teams = $east_teams . "|" . $west_teams;

my (@line1, @line2, @line3,  @line4);

my $fd;
my @vals;
my $num_lines;
my @team_line;

#
# Initialize the Hash of Teams (%HoT) to the empty set.
#
my %HoT = (
    "Eagles"          => [ ],
    "River Hawks"     => [ ],
    "Terriers"        => [ ],
    "Warriors"        => [ ],
    "Huskies"         => [ ],
    "Minutemen"       => [ ],
    "Black Bears"     => [ ],
    "Wildcats"        => [ ],

    "Badgers"         => [ ],
    "Bulldogs"        => [ ],
    "Fighting Sioux"  => [ ],
    "Tigers"          => [ ],
    "Golden Gophers"  => [ ],
    "Pioneers"        => [ ],
    "Seawolves"       => [ ],
    "Buckeyes"        => [ ],
);

open($fd, "<", "./docs/sched.csv") or die "Cannot open file: $!";

$num_lines = 0;

while (my $line = <$fd>) {
    chomp ($line);
    if ($line =~ /($tnfb_teams)/) {
        @vals = split(/,/, $line);
        shift @vals;
        if ($vals[0] eq " 27\"") {
            shift @vals;
        }
        @team_line[$num_lines] = "$vals[0],$vals[3],$vals[6],$vals[9]";
        $num_lines++;
    }
}
print "Number of lines = $num_lines\n", if (0);

close ($fd);

for (my $x = 0; $x < $num_lines; $x += 4) {
    @line1 = split(/,/, $team_line[$x]);
    @line2 = split(/,/, $team_line[($x + 1)]);
    &create_teams_played($line1[0], $line2[0]);
    &create_teams_played($line1[1], $line2[1]);
    &create_teams_played($line1[2], $line2[2]);
    &create_teams_played($line1[3], $line2[3]);

    @line3 = split(/,/, $team_line[($x + 2)]);
    @line4 = split(/,/, $team_line[($x + 3)]);
    &create_teams_played($line3[0], $line4[0]);
    &create_teams_played($line3[1], $line4[1]);
    &create_teams_played($line3[2], $line4[2]);
    &create_teams_played($line3[3], $line4[3]);
}

sub
create_teams_played {
    my ($team1, $team2) = @_;

    print "$team1 v $team2\n", if (0);

    if (grep { $_ eq $team2 } @{ $HoT{$team1} } ) {
        die "The $team1 already played the  $team2.\n";
    }
    if (grep { $_ eq $team1 } @{ $HoT{$team2} } ) {
        die "The $team2 already played the  $team1.\n";
    }
    push @{ $HoT{$team1} }, $team2;
    push @{ $HoT{$team2} }, $team1;
}

foreach my $t (sort keys %HoT) {
    my $week = 1;
    print "$t: \n";
    
    # Dereferencing the array reference at $HoT
    # print "@{ $HoT{$t} }\n";
    foreach my $oppenent (@{ $HoT{$t} }) {
        print "\tweek $week: $oppenent\n";
        $week++;
    }
    print "\n";
}
