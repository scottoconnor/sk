#! /usr/bin/perl
#
# Copyright (c) 2019, 2026 Scott O'Connor
#

use strict;
use Getopt::Long;

my $year = (1900 + (localtime)[5]);
my $cnt;
my $xx;
my $start_year = 2003;
my $html = 0;
my $weekly_stats = 0;
my $cumulative_stats = 0;
my $all_time = 0;
my $line;
my $week;
my $ret;
my $val;
my $y;
my @return;
undef(my %y);


if ($#ARGV < 0) {
    print "Usage:\n";
    print "stats.pl: -c for cumlative and/or -w for weekly\n";
    exit;
}

GetOptions (
    "w" => \$weekly_stats,
    "c" => \$cumulative_stats,
    "h" => \$html,
    "y=i" => \$year,
    "a" => \$all_time)
or die("Error in command line arguments\n");

my $num_weeks = 0;

#
# First, find how many weeks have been played in the current year.
#
for ($week = 1; $week <= 15; $week++) {
    $ret = `./skperf.pl -s -y $year -w $week | grep "Total holes played"`;
    ($val) = $ret =~ /Total holes played: (\d+)/;
    if ($val > 0) {
        $num_weeks++;
    }
}

$week = $num_weeks;

for ($y = $start_year; $y <= $year; $y++) {

    if ($all_time) {
        @return = `./skperf.pl -s -y $y`;
        while ($line = shift @return) {
            chomp ($line);
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$y}{ft} = $val;
            }
            if (($val) = $line =~ /30\047s = (\d+)/) {
                $y{$y}{thirty} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$y}{to} = $val;
            }
            if (($val) = $line =~ /Total Bogies = (\d+)/) {
                $y{$y}{tbo} = $val;
            }
            if (($val) = $line =~ /Total Pars = (\d+)/) {
                $y{$y}{tp} = $val;
            }
            if (($val) = $line =~ /Total Birdies = (\d+)/) {
                $y{$y}{tb} = $val;
            }
            if (($val) = $line =~ /Total Eagles = (\d+)/) {
                $y{$y}{te} = $val;
            }
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$y}{lsa} = $val;
            }
            if (($val) = $line =~ /Total holes played: (\d+)/) {
                $y{$y}{th} = $val;
            }
            if (($val) = $line =~ /Total Posted scores: (\d+)/) {
                $y{$y}{tposted} = $val;
            }
        }
    }

    if ($weekly_stats) {
        #
        # Weekly stats now
        #

        @return = `./skperf.pl -s -y $y -w $week`;
        while ($line = shift @return) {
            chomp ($line);
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$y}{wft} = $val;
            }
            if (($val) = $line =~ /Total 30\047s = (\d+)/) {
                defined($y{$y}{wthirty} = $val);
            }
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$y}{wlsa} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$y}{two} = $val;
            }
            if (($val) = $line =~ /Total Bogies = (\d+)/) {
                $y{$y}{twbo} = $val;
            }
            if (($val) = $line =~ /Total Pars = (\d+)/) {
                $y{$y}{twp} = $val;
            }
            if (($val) = $line =~ /Total Birdies = (\d+)/) {
                $y{$y}{twb} = $val;
            }
            if (($val) = $line =~ /Total Eagles = (\d+)/) {
                $y{$y}{twe} = $val;
            }
            if (($val) = $line =~ /Total holes played: (\d+)/) {
                $y{$y}{twh} = $val;
            }
            if (($val) = $line =~ /Total Posted scores: (\d+)/) {
                $y{$y}{twposted} = $val;
            }
        }
    }

    if ($cumulative_stats) {
        @return = `./skperf.pl -s -y $y -sw 1 -ew $week`;
        while ($line = shift @return) {
            chomp ($line);
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$y}{cft} = $val;
            }
            if (($val) = $line =~ /Total 30\047s = (\d+)/) {
                defined($y{$y}{cthirty} = $val);
            }
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$y}{clsa} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$y}{cto} = $val;
            }
            if (($val) = $line =~ /Total Bogies = (\d+)/) {
                $y{$y}{ctbo} = $val;
            }
            if (($val) = $line =~ /Total Pars = (\d+)/) {
                $y{$y}{ctp} = $val;
            }
            if (($val) = $line =~ /Total Birdies = (\d+)/) {
                $y{$y}{ctb} = $val;
            }
            if (($val) = $line =~ /Total Eagles = (\d+)/) {
                $y{$y}{cte} = $val;
            }
            if (($val) = $line =~ /Total holes played: (\d+)/) {
                $y{$y}{cth} = $val;
            }
            if (($val) = $line =~ /Total Posted scores: (\d+)/) {
                $y{$y}{tcuposted} = $val;
            }
        }
    }
}

if ($weekly_stats) {

  if ($html) {
    print "<!DOCTYPE html><font color=\"red\">
    <H2>Comparison of week $week\'s</H2>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<caption><b>League Stroke Average on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th>Stroke Average</th>
    </tr>
    \n";
  }
    print "\nLeague Stroke Average on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (sort { $y{$a}{wlsa} <=> $y{$b}{wlsa} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td><b><font color=\"red\">%.2f</font></b></td>\n    </tr>\n", $y{$xx}{wlsa}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td>%.2f</td>\n    </tr>\n", $y{$xx}{wlsa}), if $html;
        }
        printf("%2d: %d -> %.2f\n", $cnt++, $xx, $y{$xx}{wlsa}), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Scores in the 30's on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">30's</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nScores in the 30's on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{wthirty} <=> $y{$b}{wthirty} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{wthirty}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{wthirty} / $y{$xx}{twposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{wthirty}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{wthirty} / $y{$xx}{twposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{wthirty}, (($y{$xx}{wthirty} / $y{$xx}{twposted}) * 100)), if !$html;

    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Scores in the 50's on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">50's</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\n50+ on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (sort { $y{$a}{wft} <=> $y{$b}{wft} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{wft}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{wft} / $y{$xx}{twposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{wft}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{wft} / $y{$xx}{twposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{wft}, (($y{$xx}{wft} / $y{$xx}{twposted}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Others on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Others</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nOthers on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (sort { $y{$a}{two} <=> $y{$b}{two} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{two}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{two} / $y{$xx}{twh}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{two}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{two} / $y{$xx}{twh}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{two}, (($y{$xx}{two} / $y{$xx}{twh}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Bogies on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Bogies</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nBogies on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{twbo} <=> $y{$b}{twbo} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{twbo}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{twbo} / $y{$xx}{twh}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{twbo}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{twbo} / $y{$xx}{twh}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twbo}, (($y{$xx}{twbo} / $y{$xx}{twh}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Pars on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Pars</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nPars on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{twp} <=> $y{$b}{twp} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{twp}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{twp} / $y{$xx}{twh}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{twp}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{twp} / $y{$xx}{twh}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twp}, (($y{$xx}{twp} / $y{$xx}{twh}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Birdies on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Birdies</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nBirdies on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{twb} <=> $y{$b}{twb} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{twb}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{twb} / $y{$xx}{twh}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{twb}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{twb} / $y{$xx}{twh}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twb}, (($y{$xx}{twb} / $y{$xx}{twh}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Eagles on week $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Eagles</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nEagles on week $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{twe} <=> $y{$b}{twe} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{twe}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{twe} / $y{$xx}{twh}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{twe}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{twe} / $y{$xx}{twh}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{twe}, (($y{$xx}{twe} / $y{$xx}{twh}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>
    <br>
    <br>
    </body>
    </html>\n";
  }
}

if ($cumulative_stats) {

  if ($html) {
    print "<!DOCTYPE html><font color=\"red\">
    <H2>Comparison of weeks 1 through $week</H2>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<caption><b>League Stroke Average<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th>Stroke Average</th>
    </tr>
    \n";
  }
    print "\nLeague Stroke Average. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $xx (sort { $y{$a}{clsa} <=> $y{$b}{clsa} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td><b><font color=\"red\">%.2f</font></b></td>\n    </tr>\n", $y{$xx}{clsa}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td>%.2f</td>\n    </tr>\n", $y{$xx}{clsa}), if $html;
        }
        printf("%2d: %d -> %.2f\n", $cnt++, $xx, $y{$xx}{clsa}), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Scores in the 30's<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">30's</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nScores in 30's. Week 1 through $week.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{cthirty} <=> $y{$b}{cthirty} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{cthirty}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{cthirty} / $y{$xx}{tcuposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{cthirty}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{cthirty} / $y{$xx}{tcuposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cthirty}, (($y{$xx}{cthirty} / $y{$xx}{tcuposted}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Scores in the 50+<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">50+</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nScores of 50+. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $xx (sort { $y{$a}{cft} <=> $y{$b}{cft} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{cft}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{cft} / $y{$xx}{tcuposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{cft}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{cft} / $y{$xx}{tcuposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cft}, (($y{$xx}{cft} / $y{$xx}{tcuposted}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Others<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Others</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nOthers. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $xx (sort { $y{$a}{cto} <=> $y{$b}{cto} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{cto}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{cto} / $y{$xx}{cth}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{cto}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{cto} / $y{$xx}{cth}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cto}, (($y{$xx}{cto} / $y{$xx}{cth}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Bogies<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Bogies</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nBogies. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{ctbo} <=> $y{$b}{ctbo} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{ctbo}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{ctbo} / $y{$xx}{cth}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{ctbo}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{ctbo} / $y{$xx}{cth}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ctbo}, (($y{$xx}{ctbo} / $y{$xx}{cth}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Pars<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Pars</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nPars. Week 1 throught $week\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{ctp} <=> $y{$b}{ctp} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{ctp}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{ctp} / $y{$xx}{cth}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{ctp}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{ctp} / $y{$xx}{cth}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ctp}, (($y{$xx}{ctp} / $y{$xx}{cth}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Birdies<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Birdies</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nBirdies. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{ctb} <=> $y{$b}{ctb} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{ctb}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{ctb} / $y{$xx}{cth}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{ctb}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{ctb} / $y{$xx}{cth}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ctb}, (($y{$xx}{ctb} / $y{$xx}{cth}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Eagles<br>week 1 through $week</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Eagles</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nEagles. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{cte} <=> $y{$b}{cte} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{cte}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{cte} / $y{$xx}{cth}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{cte}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{cte} / $y{$xx}{cth}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{cte}, (($y{$xx}{cte} / $y{$xx}{cth}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>
    <br>
    <br>
    </body>
    </html>\n";
  }
}

if ($all_time) {

  if ($html) {
    print "<!DOCTYPE html>
    <H2>League Stats<br>Years: 2003-$year</H2>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<caption><b>League Stroke Average.</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th>Stroke Average</th>
    </tr>
    \n";
  }
    print "\nLeague Stroke Average.\n", if !$html;
    $cnt = 1;
    foreach $xx (sort { $y{$a}{lsa} <=> $y{$b}{lsa} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td><b><font color=\"red\">%.2f</font></b></td>\n    </tr>\n", $y{$xx}{lsa}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td>%.2f</td>\n    </tr>\n", $y{$xx}{lsa}), if $html;
        }
        printf("%2d: %d -> %.2f\n", $cnt++, $xx, $y{$xx}{lsa}), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Scores in the 30's</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">30's</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nScores in 30's.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{thirty} <=> $y{$b}{thirty} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{thirty}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{thirty} / $y{$xx}{tposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{thirty}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{thirty} / $y{$xx}{tposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{thirty}, (($y{$xx}{thirty} / $y{$xx}{tposted}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Scores in the 50+</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">50+</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nScores in the 50+.\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{ft} <=> $y{$b}{ft} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{ft}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{ft} / $y{$xx}{tposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{ft}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{ft} / $y{$xx}{tposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{ft}, (($y{$xx}{ft} / $y{$xx}{tposted}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Others</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Others</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nOthers\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{to} <=> $y{$b}{to} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{to}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{to} / $y{$xx}{tposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{to}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{to} / $y{$xx}{tposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{to}, (($y{$xx}{to} / $y{$xx}{th}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Bogies</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Bogies</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nBogies\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{tbo} <=> $y{$b}{tbo} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{tbo}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{tbo} / $y{$xx}{tposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{tbo}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{tbo} / $y{$xx}{tposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{tbo}, (($y{$xx}{tbo} / $y{$xx}{th}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Pars</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Pars</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nPars\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{tp} <=> $y{$b}{tp} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{tp}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{tp} / $y{$xx}{tposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{tp}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{tp} / $y{$xx}{tposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{tp}, (($y{$xx}{tp} / $y{$xx}{th}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Birdies</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Birdies</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nBirdies\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{tb} <=> $y{$b}{tb} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{tb}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{tb} / $y{$xx}{tposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{tb}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{tb} / $y{$xx}{tposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{tb}, (($y{$xx}{tb} / $y{$xx}{th}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }

  if ($html) {
    print "<!DOCTYPE html>
    <html>
    <head>
    <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
    }
    </style>
    </head>
    <body>
    <table style=\"width:30%\">
    ";
  }
  print "<br><br>\n", if $html;
  print "<caption><b>Eagles</b></caption>", if $html;
  if ($html) {
    print "
    <tr>
      <th>Rank</th>
      <th>Year</th>
      <th style=\"text-align:center\">Eagles</th>
      <th>Percentage</th>
    </tr>
    \n";
  }
    print "\nEagles\n", if !$html;
    $cnt = 1;
    foreach $xx (reverse sort { $y{$a}{te} <=> $y{$b}{te} } (keys(%y))) {
        if ($xx == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$xx}{te}), if $html;
            printf("      <td><b><font color=\"red\">%.2f\%</font></b></td>\n    </tr>\n", (($y{$xx}{te} / $y{$xx}{tposted}) * 100)), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $xx), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$xx}{te}), if $html;
            printf("      <td>%.2f\%</td>\n    </tr>\n", (($y{$xx}{te} / $y{$xx}{tposted}) * 100)), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $xx, $y{$xx}{te}, (($y{$xx}{te} / $y{$xx}{th}) * 100)), if !$html;
    }
  if ($html) {
    print "
    </table>
    <br>
    <br>
    </body>
    </html>\n";
  }
}
