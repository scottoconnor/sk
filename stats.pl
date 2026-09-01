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
my $line;
my $week;
my $ret;
my $val;
my $sy;
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
    "y=i" => \$year)
or die("Error in command line arguments\n");

$ret = qx(./skperf.pl -s -y $year | grep \"Total holes played\");
($val) = $ret =~ /Total holes played: (\d+)/;
$week = ceil(($val/288));

for ($sy = $start_year; $sy <= $year; $sy++) {

    if ($weekly_stats) {
        @return = qx{./skperf.pl -s -y $sy -w $week};
        while ($line = shift @return) {
            chomp ($line);
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$sy}{wlsa} = $val;
            }
            if (($val) = $line =~ /Total 30\047s = (\d+)/) {
                $y{$sy}{wthirty} = $val;
            }
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$sy}{wft} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$sy}{two} = $val;
            }
            if (($val) = $line =~ /Total Double Bogies = (\d+)/) {
                $y{$sy}{twdbo} = $val;
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
            if (($val) = $line =~ /League Stroke Average = (\d+\056\d+)/) {
                $y{$sy}{clsa} = $val;
            }
            if (($val) = $line =~ /Total 30\047s = (\d+)/) {
                $y{$sy}{cthirty} = $val;
            }
            if (($val) = $line =~ /50\053 = (\d+)/) {
                $y{$sy}{cft} = $val;
            }
            if (($val) = $line =~ /Total Others = (\d+)/) {
                $y{$sy}{cto} = $val;
            }
            if (($val) = $line =~ /Total Double Bogies = (\d+)/) {
                $y{$sy}{ctdbo} = $val;
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

#
# Print Header for comparison of individual weeks.
#
if ($weekly_stats) {
  print "<!DOCTYPE html><font color=\"red\">
  <H2>Comparison of week $week\'s</H2>\n", if $html;
  print "Comparison of week $week\'s\n", if !$html;

  #
  # set start week to 0 so we know to only print out
  &print_html_text_table(\%y, $sy, 0, $week, "Stroke Average", "wlsa");
  &print_html_text_table(\%y, $sy, 0, $week, "Scores in the 30\'s", "wthirty");
  &print_html_text_table(\%y, $sy, 0, $week, "Scores in the 50\'s", "wft");
  &print_html_text_table(\%y, $sy, 0, $week, "Others", "two");
  &print_html_text_table(\%y, $sy, 0, $week, "Double Bogies", "twdbo");
  &print_html_text_table(\%y, $sy, 0, $week, "Bogies", "twbo");
  &print_html_text_table(\%y, $sy, 0, $week, "Pars", "twp");
  &print_html_text_table(\%y, $sy, 0, $week, "Birdies", "twb");
  &print_html_text_table(\%y, $sy, 0, $week, "Eagles", "twe");
}

if ($cumulative_stats) {
  print "<!DOCTYPE html><font color=\"red\">
  <H2>Comparison of weeks 1 through $week</H2>\n", if $html;
  print "\n\nComparison of week 1 through $week\n", if !$html;

  &print_html_text_table(\%y, $sy, 1, $week, "Stroke Average", "clsa");
  &print_html_text_table(\%y, $sy, 1, $week, "Scores in the 30\'s", "cthirty");
  &print_html_text_table(\%y, $sy, 1, $week, "Scores in the 50\'s", "cft");
  &print_html_text_table(\%y, $sy, 1, $week, "Others", "ctdbo");
  &print_html_text_table(\%y, $sy, 1, $week, "Double Bogies", "twdbo");
  &print_html_text_table(\%y, $sy, 1, $week, "Bogies", "ctbo");
  &print_html_text_table(\%y, $sy, 1, $week, "Pars", "ctp");
  &print_html_text_table(\%y, $sy, 1, $week, "Birdies", "ctb");
  &print_html_text_table(\%y, $sy, 1, $week, "Eagles", "cte");
}

sub
print_html_text_table {

  my ($y, $sy, $sw, $week, $stat_name, $stat) = @_;

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
  ", if ($html);
  print "<caption><b>$stat_name on week $week</b></caption>", if ($html && ($sw == 0));
  print "<caption><b>$stat_name week 1 through $week</b></caption>", if ($html && ($sw == 1));
  if ($html) {
    print "
    <tr>
      <th style=\"padding-left: 7px\">Rank</th>
      <th style=\"text-align:center\">Year</th>
      <th style=\"text-align:center\">$stat_name</th>
    </tr>
    \n";
  }
  print "\n$stat_name on week $week.\n", if (!$html && ($sw == 0));
  print "\n$stat_name week 1 through $week\n", if (!$html && ($sw == 1));
  $cnt = 1;
  foreach $key (sort { $y{$a}{$stat} <=> $y{$b}{$stat} } (keys(%y))) {
      if ($key == $year) {
          printf("<tr><td style=\"padding-left: 7px\"><b><font color=\"red\">%d</font></b></td>\n", $cnt++), if $html;
          printf("<td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n", $key), if $html;
          if ($html && (($stat eq "wlsa") || ($stat eq "clsa"))) {
            printf("<td style=\"text-align:center\"><b><font color=\"red\">%.2f</font></b></td>\n",
                $y{$key}{$stat}), if ($html);
          } else {
            printf("<td style=\"text-align:center\"><b><font color=\"red\">%d</font></b></td>\n",
                $y{$key}{$stat}), if ($html);
          }
      } else {
          printf("<tr><td style=\"padding-left: 7px\">%2d</td>\n", $cnt++), if $html;
          printf("<td style=\"text-align:center\">%d</td>\n", $key), if $html;
          if ($html && (($stat eq "wlsa") || ($stat eq "clsa"))) {
            printf("<td style=\"text-align:center\">%.2f\n</td>\n", $y{$key}{$stat}), if ($html);
          } else {
            printf("<td style=\"text-align:center\">%d\n</td>\n", $y{$key}{$stat}), if ($html);
          }
      }
      if (($stat eq "wlsa") || ($stat eq "clsa")) {
          printf("%2d: %d -> %.2f\n", $cnt++, $key, $y{$key}{$stat}), if (!$html);
      } else {
          printf("%2d: %d -> %d\n", $cnt++, $key, $y{$key}{$stat}), if (!$html);
      }
  }
  if ($html) {
    print "
    </table>

    </body>
    </html>\n";
  }
  print "<br><br>\n", if $html;
}
