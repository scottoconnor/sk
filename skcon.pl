#! /usr/bin/perl
#
# Copyright (c) 2018, 2023 Scott O'Connor
#

require './tnfb.pl';
require './courses.pl';
require './hcroutines.pl';

use GDBM_File;

#
# These are the number of scores that should be added each week.
#
$num_NF_scores = 12;
$num_SF_scores = 12;
$num_SB_scores =  8;

$nine{'NF'} = 0;
$nine{'SF'} = 0;
$nine{'SB'} = 0;
$num_scores = 0;

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
    my($d, $cch, $ch, $hi, $ph);

    open(FD, $fn);

    $fnnew = $fnnew . ".gdbm";

    tie %tnfb_db, 'GDBM_File', $fnnew, GDBM_WRCREAT, 0644
        or die "$GDBM_File::gdbm_errno";

    # First line is the ScoreKeeper tag, throw it away
    # to get to the players name.
    $line = <FD>;

    $line = <FD>;
    $line =~ s/"//g;
    ($last, $first) = split(/,/, $line);
    $last =~ s/^\s+|\s+$//g;
    $first =~ s/^\s+|\s+$//g;
    $pn = $first . " " . $last;

    if (!defined($golfers{$fn})) {
        untie %tnfb_db;
        close(FD);
        die "$pn: Unknown golfer: might need to run build-golfers.pl\n";
    }

    $tnfb_db{'Player'} = "$pn";
    $tnfb_db{'Team'} = $golfers{$fn}->{team};
    $tnfb_db{'Active'} = $golfers{$fn}->{active};
    
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
                untie %tnfb_db;
                close(FD);
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

        $d = "$year-$month-$day";

        if (exists $tnfb_db{$d}) {
            #print "entry exists: $pn, $d, $tnfb_db{$d}\n";
            $line = <FD>;
            $line = <FD>;
            $line = <FD>;
            $line = <FD>;
            $line = <FD>;
            $line = <FD>;
            next;
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

        $team = "Team_" . $year;
        if ($year >= 2022 && !exists($tnfb_db{$team})) {
            $tnfb_db{$team} = $golfers{$fn}->{team};
        }

        $nine{$course}++;
        $num_scores++;

        $hi = $tnfb_db{'Current'};

        #
        # If the player does not have enough scores for a stable index,
        # input here what they player played at that night.
        #
        if ($hi == -100) { 
            #
            # Enter the player's index determined before the round.
            #
            print "Enter index for $pn: ";
            $hi = <STDIN>;
            chomp $hi;
            print "$pn: using handicap index of -> $hi\n"
        }

        $ccd = ($c{$course}{course_rating} - $c{$course}{par});
        $ccd = round($ccd, 10);
        $ch = (($hi * ($c{$course}->{slope} / 113)) + $ccd);
        $cch = sprintf("%.0f", ($ch * 1.0));
        $ph = sprintf("%.0f", ($ch * 0.9));
        $ph = abs($ph), if ($ph == 0.0);

        if ($line =~ /^\d{9}\054/) {

            #
            # A 9,0 format is score where each hole has a single digit score.
            #
            $db_out = "$course:$course_rating:$slope:$d:$hi:$ph:$shot:$post";

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)/;

            if ($year >= 2020) {
                $post = net_double_bogey($cch, $course, @a);
            }

            $count = 1;
            while (defined($v = shift(@a))) {
                $v = abs($v);
                if ($v == 0) { $v = 10 };
                if ($v == 1 && $c{$course}->{$count}[0] > 3) { $v = 11 };
                $db_out = $db_out . ":$v";
                $check_shot += $v;
                $count++;
            }
            $tnfb_db{$d} = $db_out;

            if ($check_shot != $shot) {
                print STDOUT "$pn, $month-$day-$year: 9,0: shot -> $shot, check_shot -> $check_shot.\n";
            }
        } elsif ($line =~ /^\d{8}\054/) {

            #
            # A 8,0 format is a score with a 10 on the first hole.
            #

            ($a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d)(\d)(\d)(\d)(\d)(\d)(\d)/;

            $a[0] = 10;

            if ($year >= 2020) {
                $post = net_double_bogey($cch, $course, @a);
            }

            $db_out = "$course:$course_rating:$slope:$d:$hi:$ph:$shot:$post";

            $count = 1;
            while (defined($v = shift(@a))) {
                $v = abs($v);
                if ($v == 0) { $v = 10 };
                if ($v == 1 && $c{$course}->{$count}[0] > 3) { $v = 11 };
                $db_out = $db_out . ":$v";
                $check_shot += $v;
                $count++;
            }
            $tnfb_db{$d} = $db_out;

            if ($check_shot != $shot) {
                print STDOUT "$pn, $month-$day-$year: 8,0: shot -> $shot, check_shot -> $check_shot.\n";
            }
        } elsif ($line =~ /^\d{13}\056\d{3}\054/) {

            #
            # A 13,3 format is a score with a 10 on the last hole.
            #

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d)\054/;

            if ($a[8] != 1 && $a[8] != 2) {
                untie %tnfb_db;
                close(FD);
                die "Last hole should be 1 or 2 (which is a 10 or 20): line: $line\n";
            }

            $a[8] *= 10;     # 10 or 20 in his format

            if ($year >= 2020) {
                $post = net_double_bogey($cch, $course, @a);
            }

            $db_out = "$course:$course_rating:$slope:$d:$hi:$ph:$shot:$post";

            while (defined($v = shift(@a))) {
                $v = abs($v);
                $db_out = $db_out . ":$v";
                $check_shot += $v;
            }
            $tnfb_db{$d} = $db_out;

            if ($check_shot != $shot) {
                print STDOUT "$pn, $month-$day-$year: 13,3: shot -> $shot, check_shot -> $check_shot.\n";
            }
        } elsif ($line =~ /^\d{13}\056\d{4}\054/) {

            #
            # A 13,4 format is a score with big number on hole #9.
            #

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d)(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d{2})\054/;

            if ($year >= 2020) {
                $post = net_double_bogey($cch, $course, @a);
            }

            $db_out = "$course:$course_rating:$slope:$d:$hi:$ph:$shot:$post";

            while (defined($v = shift(@a))) {
                $v = abs($v);
                $db_out = $db_out . ":$v";
                $check_shot += $v;
            }
            $tnfb_db{$d} = $db_out;

            if ($check_shot != $shot) {
                print STDOUT "$pn, $month-$day-$year: 13,4: shot -> $shot, check_shot -> $check_shot.\n";
            }
        } elsif ($line =~ /^\d{14}\056\d{3}\054/) {

            #
            # A 14,3 format is a score with big number on hole #1 and a 10 on the last hole.
            #

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d)\054/;

            $a[8] = 10;  # in this format

            if ($year >= 2020) {
                $post = net_double_bogey($cch, $course, @a);
            }

            $db_out = "$course:$course_rating:$slope:$d:$hi:$ph:$shot:$post";

            while (defined($v = shift(@a))) {
                $v = abs($v);
                $db_out = $db_out . ":$v";
                $check_shot += $v;
            }
            $tnfb_db{$d} = $db_out;

            if ($check_shot != $shot) {
                print STDOUT "$pn, $month-$day-$year: 14,3: shot -> $shot, check_shot -> $check_shot.\n";
            }
        } elsif ($line =~ /^\d{14}\056\d{4}\054/) {

            #
            # 14,4 format have scores that hole number 1 is a 10 or higher.
            #

            ($a[0], $a[1], $a[2], $a[3], $a[4], $a[5], $a[6], $a[7], $a[8]) = $line =~
                /^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\056(\d{2})(\d{2})\054/;

            if ($year >= 2020) {
                $post = net_double_bogey($cch, $course, @a);
            }

            $db_out = "$course:$course_rating:$slope:$d:$hi:$ph:$shot:$post";

            while (defined($v = shift(@a))) {
                $v = abs($v);
                $db_out = $db_out . ":$v";
                $check_shot += $v;
            }
            $tnfb_db{$d} = $db_out;

            if ($check_shot != $shot) {
                print STDOUT "$pn, $month-$day-$year: 14,4: shot -> $shot, check_shot -> $check_shot.\n";
            }
        } elsif ($line =~ /^0\0540/) {
            #
            # This is a non hole-by-hole score. "0,0" in ScoreKeeper file
            #
            $db_out = "$course:$course_rating:$slope:$d:$hi:$ph:$shot:$post";
            $tnfb_db{$d} = $db_out;
        } else {
            delete($tnfb_db{$team});
            print "Unexpected line: $fn: $line -- $course\n"
        }
        $line = <FD>;
        $line = <FD>;
        $line = <FD>;
    }

    $new_hi = gen_hi();
    $tnfb_db{'Current'} = $new_hi;

    untie %tnfb_db;
    close(FD);
}

if ($num_scores != 0 && $num_scores != 32) {
    print "Wrong number of scores added: $num_scores\n";
} else {
    print "$num_scores scores added.\n";
}

if ($nine{'NF'} != 0 && $nine{'NF'} != $num_NF_scores) {
    print "Wrong number of NF scores: $nine{'NF'}\n";
}

if ($nine{'SF'} != 0 && $nine{'SF'} != $num_SF_scores) {
    print "Wrong number of SF scores: $nine{'SF'}\n";
}

if ($nine{'SB'} != 0 && $nine{'SB'} != $num_SB_scores) {
    print "Wrong number of SB scores: $nine{'SB'}\n";
}

#
# Take the players round, calculate current course handicap and figure
# out their net double bogey for each hole.
#
sub
net_double_bogey {
    my ($cch, $course, @s) = @_;
    my ($v, $hole, $post);

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
