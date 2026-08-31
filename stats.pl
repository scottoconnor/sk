#! /usr/bin/perl
#
# Copyright (c) 2019, 2026 Scott O'Connor
#

use strict;
use Getopt::Long;
use POSIX;

my $year = (1900 + (localtime)[5]);
my $cnt;
my $key;
my $start_year = 2003;
my $html = 0;
my $weekly_stats = 0;
my $cumulative_stats = 0;
my $all_time = 0;
my $line;
my $week;
my $ret;
my $val;
my $sy;
my $num_weeks = 0;
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

$num_weeks = 0;

$ret = qx(./skperf.pl -s -y $year | grep \"Total holes played\");
($val) = $ret =~ /Total holes played: (\d+)/;
$num_weeks = ceil(($val/288));

$week = $num_weeks;

for ($sy = $start_year; $sy <= $year; $sy++) {

    if ($all_time) {
        @return = qx{./skperf.pl -s -y $sy};
        while ($line = shift @return) {
            chomp ($line);
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$sy}{ft} = $val;
            }
            if (($val) = $line =~ /30\047s = (\d+)/) {
                $y{$sy}{thirty} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$sy}{to} = $val;
            }
            if (($val) = $line =~ /Total Bogies = (\d+)/) {
                $y{$sy}{tbo} = $val;
            }
            if (($val) = $line =~ /Total Pars = (\d+)/) {
                $y{$sy}{tp} = $val;
            }
            if (($val) = $line =~ /Total Birdies = (\d+)/) {
                $y{$sy}{tb} = $val;
            }
            if (($val) = $line =~ /Total Eagles = (\d+)/) {
                $y{$sy}{te} = $val;
            }
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$sy}{lsa} = $val;
            }
            if (($val) = $line =~ /Total holes played: (\d+)/) {
                $y{$sy}{th} = $val;
            }
            if (($val) = $line =~ /Total Posted scores: (\d+)/) {
                $y{$sy}{tposted} = $val;
            }
        }
    }

    if ($weekly_stats) {
        #
        # Weekly stats now
        #

        @return = qx{./skperf.pl -s -y $sy -w $week};
        while ($line = shift @return) {
            chomp ($line);
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$sy}{wft} = $val;
            }
            if (($val) = $line =~ /Total 30\047s = (\d+)/) {
                $y{$sy}{wthirty} = $val;
            }
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$sy}{wlsa} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$sy}{two} = $val;
            }
            if (($val) = $line =~ /Total Bogies = (\d+)/) {
                $y{$sy}{twbo} = $val;
            }
            if (($val) = $line =~ /Total Pars = (\d+)/) {
                $y{$sy}{twp} = $val;
            }
            if (($val) = $line =~ /Total Birdies = (\d+)/) {
                $y{$sy}{twb} = $val;
            }
            if (($val) = $line =~ /Total Eagles = (\d+)/) {
                $y{$sy}{twe} = $val;
            }
        }
    }

    if ($cumulative_stats) {
        @return = qx{./skperf.pl -s -y $sy -sw 1 -ew $week};
        while ($line = shift @return) {
            chomp ($line);
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$sy}{cft} = $val;
            }
            if (($val) = $line =~ /Total 30\047s = (\d+)/) {
                $y{$sy}{cthirty} = $val;
            }
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$sy}{clsa} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$sy}{cto} = $val;
            }
            if (($val) = $line =~ /Total Bogies = (\d+)/) {
                $y{$sy}{ctbo} = $val;
            }
            if (($val) = $line =~ /Total Pars = (\d+)/) {
                $y{$sy}{ctp} = $val;
            }
            if (($val) = $line =~ /Total Birdies = (\d+)/) {
                $y{$sy}{ctb} = $val;
            }
            if (($val) = $line =~ /Total Eagles = (\d+)/) {
                $y{$sy}{cte} = $val;
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
    <table style=\"width:20%\">
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
    foreach $key (sort { $y{$a}{wlsa} <=> $y{$b}{wlsa} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%.2f</font></b></td>\n", $y{$key}{wlsa}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("       <td style=\"text-align:center\">%.2f\n</td>", $y{$key}{wlsa}), if $html;
        }
        printf("%2d: %d -> %.2f\n", $cnt++, $key, $y{$key}{wlsa}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nScores in the 30's on week $week.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{wthirty} <=> $y{$b}{wthirty} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{wthirty}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{wthirty}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{wthirty}), if !$html;

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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\n50+ on week $week.\n", if !$html;
    $cnt = 1;
    foreach $key (sort { $y{$a}{wft} <=> $y{$b}{wft} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{wft}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{wft}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{wft}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nOthers on week $week.\n", if !$html;
    $cnt = 1;
    foreach $key (sort { $y{$a}{two} <=> $y{$b}{two} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{two}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{two}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{two}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nBogies on week $week.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{twbo} <=> $y{$b}{twbo} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{twbo}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{twbo}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{twbo}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nPars on week $week.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{twp} <=> $y{$b}{twp} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{twp}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{twp}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{twp}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nBirdies on week $week.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{twb} <=> $y{$b}{twb} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{twb}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{twb}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{twb}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nEagles on week $week.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{twe} <=> $y{$b}{twe} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{twe}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{twe}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{twe}), if !$html;
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
    <table style=\"width:20%\">
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
    foreach $key (sort { $y{$a}{clsa} <=> $y{$b}{clsa} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            #printf("      <td><b><font color=\"red\">%.2f</font></b></td>\n    </tr>\n", $y{$key}{clsa}), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%.2f</font></b></td>\n", $y{$key}{clsa}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            #printf("      <td>%.2f</td>\n    </tr>\n", $y{$key}{clsa}), if $html;
            printf("      <td style=\"text-align:center\">%.2f\n</td>", $y{$key}{clsa}), if $html;
        }
        printf("%2d: %d -> %.2f\n", $cnt++, $key, $y{$key}{clsa}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nScores in 30's. Week 1 through $week.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{cthirty} <=> $y{$b}{cthirty} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{cthirty}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{cthirty}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{cthirty}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nScores of 50+. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $key (sort { $y{$a}{cft} <=> $y{$b}{cft} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{cft}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{cft}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{cft}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nOthers. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $key (sort { $y{$a}{cto} <=> $y{$b}{cto} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{cto}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{cto}), if $html;
        }
        printf("%2d: %d -> %d\n", $cnt++, $key, $y{$key}{cto}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nBogies. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{ctbo} <=> $y{$b}{ctbo} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{ctbo}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{ctbo}), if $html;
        }
        printf("%2d: %d -> %d\n", $cnt++, $key, $y{$key}{ctbo}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nPars. Week 1 throught $week\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{ctp} <=> $y{$b}{ctp} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{ctp}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{ctp}), if $html;
        }
        printf("%2d: %d -> %d\n", $cnt++, $key, $y{$key}{ctp}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nBirdies. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{ctb} <=> $y{$b}{ctb} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{ctb}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{ctb}), if $html;
        }
        printf("%2d: %d -> %2d\n", $cnt++, $key, $y{$key}{ctb}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nEagles. Week 1 through $week\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{cte} <=> $y{$b}{cte} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{cte}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{cte}), if $html;
        }
        printf("%2d: %d -> %d\n", $cnt++, $key, $y{$key}{cte}), if !$html;
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
    <table style=\"width:20%\">
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
    foreach $key (sort { $y{$a}{lsa} <=> $y{$b}{lsa} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td><b><font color=\"red\">%.2f</font></b></td>\n    </tr>\n", $y{$key}{lsa}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td>%.2f</td>\n    </tr>\n", $y{$key}{lsa}), if $html;
        }
        printf("%2d: %d -> %.2f\n", $cnt++, $key, $y{$key}{lsa}), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nScores in 30's.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{thirty} <=> $y{$b}{thirty} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{thirty}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{thirty}), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $key, $y{$key}{thirty}, (($y{$key}{thirty} / $y{$key}{tposted}) * 100)), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nScores in the 50+.\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{ft} <=> $y{$b}{ft} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{ft}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{ft}), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $key, $y{$key}{ft}, (($y{$key}{ft} / $y{$key}{tposted}) * 100)), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nOthers\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{to} <=> $y{$b}{to} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{to}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{to}), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $key, $y{$key}{to}, (($y{$key}{to} / $y{$key}{th}) * 100)), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nBogies\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{tbo} <=> $y{$b}{tbo} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{tbo}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{tbo}), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $key, $y{$key}{tbo}, (($y{$key}{tbo} / $y{$key}{th}) * 100)), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nPars\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{tp} <=> $y{$b}{tp} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{tp}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{tp}), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $key, $y{$key}{tp}, (($y{$key}{tp} / $y{$key}{th}) * 100)), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nBirdies\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{tb} <=> $y{$b}{tb} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{tb}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{tb}), if $html;
        }
        printf("%2d: %d -> %2d  (%.2f\%)\n", $cnt++, $key, $y{$key}{tb}, (($y{$key}{tb} / $y{$key}{th}) * 100)), if !$html;
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
    <table style=\"width:20%\">
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
    </tr>
    \n";
  }
    print "\nEagles\n", if !$html;
    $cnt = 1;
    foreach $key (reverse sort { $y{$a}{te} <=> $y{$b}{te} } (keys(%y))) {
        if ($key == $year) {
            printf("    <tr>\n      <td><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
            printf("      <td><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $y{$key}{te}), if $html;
        } else {
            printf("    <tr>\n      <td>%2d</td>\n", $cnt++), if $html;
            printf("      <td>%d</td>\n", $key), if $html;
            printf("      <td style=\"text-align:center\">%d</td>\n", $y{$key}{te}), if $html;
        }
        printf("%2d: %d -> %d  (%.2f\%)\n", $cnt++, $key, $y{$key}{te}, (($y{$key}{te} / $y{$key}{th}) * 100)), if !$html;
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
