#! /usr/bin/perl
#
# Copyright (c) 2018, 2022 Scott O'Connor
#

require './tnfb.pl';
require './courses.pl';
require './hcroutines.pl';

#
# Need to look up each player's trend to get their current
# handicap index. This is needed for calculating net double bogie
# for the World Handicap System.
#
open(TD, "trend"), or die "Can't open file trend.\n";
my (@ary);

while (<TD>) {
    @ary = split(/:/, $_);

    if ($ary[2] ne "current") {
        $index{$ary[0]}{$ary[2]} = $ary[5];
    } else {
        chop($ary[3]);
        $index{$ary[0]}{$ary[2]} = $ary[3];
    }
}
close(TD);

opendir($dh, "./golfers") || die "Can't open \"golfers\" directory.";

while (readdir $dh) {
    if ($_ =~ /^\d+\056ID/) {
        push @golfer_list, $_;
    }
}
closedir ($dh);

@golfer_list = sort @golfer_list;

while ($fna = shift @golfer_list) {
    ($nfna) = $fna =~ /(\d+)\056ID/;
    $nfna += 1000;
    unlink "golfers/$nfna", if (-e "golfers/$nfna");
    convert_player("golfers/$fna", "golfers/$nfna");
}

sub convert_player {

    my($fn) = $_[0];
    my($fnnew) = $_[1];

    open(FD, $fn);
    open(NFD, ">", $fnnew); 

    # First line is the ScoreKeeper tag, throw it away
    # to get to the players name.
    $line = <FD>;

    $line = <FD>;
    $line =~ s/"//g;
    ($last, $first) = split(/,/, $line);
    $last =~ s/^\s+|\s+$//g;
    $first =~ s/^\s+|\s+$//g;
    $pn = $first . " " . $last;

    if (defined($golfers{$fn})) {
        print NFD "$first:$last:$golfers{$fn}->{team}:$golfers{$fn}->{active}\n";
    } else {
        close(FD);
        close(NFD); 
        die "$first $last: Unknown golfer: might need to run build-golfers.pl\n";
    }

    $line = <FD>;
    $line = <FD>;
    $line = <FD>;
    $line = <FD>;
    $line = <FD>;
    $line = <FD>;
    $line = <FD>;

    while ($line = <FD>) {

        if ($line =~ /^\d{6,7}\054/) {
            $num = @fields = split(',', $line);
            if ($num != 8) {
                close(FD);
                close(NFD); 
                die "Error on getting date, shot, post! line: $line\n";
            }
            if ($fields[2] != 0 && $fields[3] != 0) {
                # 18-Hole score.
                $shot = @fields[5];
            } else {
                # 9-Hole score.
                $shot = @fields[4];
            }
            $date = @fields[0];
            $post = @fields[6];

            if ($line =~ /^9\d{5}/) {
                ($year, $month, $day) = $line =~ /(9\d)(\d\d)(\d\d)/;
                $year = "19" . $year;
                $month = abs($month);
                $day = abs($day);
            } elsif ($line =~ /^1\d{6}/) {
                ($year, $month, $day) = $line =~ /^1(\d\d)(\d\d)(\d\d)/;
                $year = "20" . $year;
                $month = abs($month);
                $day = abs($day);
            } else {
                print "Can't determine date!\n";
            }
        }

        chomp($line = <FD>);
        ($course_rating, $slope, $course) = split(/,/, $line);

        if ($course =~ /Stow\/South Front/) {
            $course = 'SF';
            $course_rating = $c{$course}{course_rating};
            $slope = $c{$course}{slope};
        } elsif ($course =~ /Stow\/South Back/) {
            $course = 'SB';
            $course_rating = $c{$course}{course_rating};
            $slope = $c{$course}{slope};
        } elsif ($course =~ /Stow\/North Front/) {
            $course = 'NF';
            $course_rating = $c{$course}{course_rating};
            $slope = $c{$course}{slope};
        } elsif ($course =~ /Stow\/North Back/) {
            $course = 'NB';
            $course_rating = $c{$course}{course_rating};
            $slope = $c{$course}{slope};
        } else {
            # non-league or away course.
            $course = 'NL';
        }

        $line = <FD>;
        chomp($line = <FD>);

        $check_shot = 0;

        if ($line =~ /^\d{9}\054/) {

            #
            # A 9,0 format is score where each hole has a single digit score.
            #

            print NFD "$course:$course_rating:$slope:$year-$month-$day:$shot:$post";

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)/;

            $count = 1;
            while (defined($v = shift(@a))) {
                $v = abs($v);
                if ($v == 0) { $v = 10 };
                if ($v == 1 && $c{$course}->{$count}[0] > 3) { $v = 11 };
                print NFD ":$v";
                $check_shot += $v;
                $count++;
            }
            print NFD "\n";

            if ($check_shot != $shot) {
                print "9,0: $fn: $shot: $check_shot, Incorrect! -- $line\n";
            }
        } elsif ($line =~ /^\d{8}\054/) {

            #
            # A 8,0 format is a score with a 10 on the first hole.
            #

            ($a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)/;

            $a[0] = 10;

            if ($year >= 2020) {
                $post = net_double_bogey($pn, "$year-$month-$day", $course, @a);
            }

            print NFD "$course:$course_rating:$slope:$year-$month-$day:$shot:$post";

            $count = 1;
            while (defined($v = shift(@a))) {
                $v = abs($v);
                if ($v == 0) { $v = 10 };
                if ($v == 1 && $c{$course}->{$count}[0] > 3) { $v = 11 };
                print NFD ":$v";
                $check_shot += $v;
                $count++;
            }
            print NFD "\n";

            if ($check_shot != $shot) {
                print "8,0: $fn: $shot: $check_shot, Incorrect! -- $line\n";
            }
        } elsif ($line =~ /^\d{13}\056\d{3}\054/) {

            #
            # A 13,3 format is a score with a 10 on the last hole.
            #

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d)\054/;

            if ($a[8] != 1 && $a[8] != 2) {
                close(FD);
                close(NFD); 
                die "Last hole should be 1 or 2 (which is a 10 or 20): line: $line\n";
            }

            $a[8] *= 10;     # 10 or 20 in his format

            if ($year >= 2020) {
                $post = net_double_bogey($pn, "$year-$month-$day", $course, @a);
            }

            print NFD "$course:$course_rating:$slope:$year-$month-$day:$shot:$post";

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

            #
            # A 13,4 format is a score with big number on hole #9.
            #

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d{2})\054/;

            if ($year >= 2020) {
                $post = net_double_bogey($pn, "$year-$month-$day", $course, @a);
            }

            print NFD "$course:$course_rating:$slope:$year-$month-$day:$shot:$post";

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

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d)\054/;

            $a[8] = 10;  # in this format

            if ($year >= 2020) {
                $post = net_double_bogey($pn, "$year-$month-$day", $course, @a);
            }

            print NFD "$course:$course_rating:$slope:$year-$month-$day:$shot:$post";

            while (defined($v = shift(@a))) {
                $v = abs($v);
                print NFD ":$v";
                $check_shot += $v;
            }
            print NFD "\n";

            if ($check_shot != $shot) {
                print "13,3: $shot: $check_shot, Incorrect!\n";
            }
        } elsif ($line =~ /^\d{14}\056\d{4}\054/) {

            #
            # 14,4 format have scores that hole number 1 is a 10 or higher.
            #

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d{2})\054/;

            if ($year >= 2020) {
                $post = net_double_bogey($pn, "$year-$month-$day", $course, @a);
            }

            print NFD "$course:$course_rating:$slope:$year-$month-$day:$shot:$post";

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
            #
            # This is a non hole-by-hole score. "0,0" in ScoreKeeper file
            #
            print NFD "$course:$course_rating:$slope:$year-$month-$day:$shot:$post\n";
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

#
# Take the players round, calculate current course handicap and figure
# out their net double bogey for each hole.
#
sub net_double_bogey {
    my ($pn, $date, $course, @s) = @_;
    my ($v, $hole, $post, $hi);

    # 
    # If the player does not have a valid index due to lack of scores,
    # set their handicap intex to 20.5 and flag it (and probably ignore it).
    #
    if (defined($index{$pn}{$date})) {
        $hi = $index{$pn}{$date};
    } elsif (!defined($index{$pn}{$date}) && defined($index{$pn}{"current"})) {
        $hi = $index{$pn}{"current"};
    } else {
        #
        # If a player doesn't have a current index, allow a stroke per hole.
        #
        $hi = 20.5;
        print "$pn: using handicap index of -> 20.5\n"
    }

    #
    # Figure out the players current course handicap (cch)
    #
    $cd  = ($c{$course}{course_rating} - $c{$course}{par});
    $cd  = round($cd, 10);
    $cch = (($hi * ($c{$course}->{slope} / 113)) + $cd);
    $cch = sprintf("%.0f", $cch);

    $hole = 1; $post = 0;
    while (defined($v = shift(@s))) {
        $v = abs($v);

        #
        # Each player is allowed double bogey on each hole.  If the
        # hole is one of the player's handicap hole, they are allowed
        # one or more strokes.
        #
        $max_score = ($c{$course}{$hole}[0] + 2);

        $add_stroke = ($cch - $c{$course}{$hole}[1]);
        if ($add_stroke >= 0 && $add_stroke < 9) {
            $max_score++;
        }
        if ($add_stroke >= 9) {
            $max_score += 2;
        }
        #if ($c{$course}{$hole}[1] <= $cch) { $max_score++ };

        $post += ($v > $max_score) ? $max_score : $v;
        $hole++;
    }
    return ($post);
}
