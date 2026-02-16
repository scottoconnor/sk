#! /usr/bin/perl
#
# Copyright (c) 2026, Scott O'Connor
#

require './subs.pl';

my ($total_subs) = 0;
my ($total_years) = 0;
my ($num_weeks) = 0;
my $year_subs;
my $w;

foreach my $year (sort keys %subs) {
    $year_subs = 0;
    for ($w = 1; $w < 16; $w++) {
        $num_weeks++;
        if (!defined($subs{$year}{$w})) {
            next;
        }
        %s = %{$subs{$year}{$w}};
        $size = keys(%s);
        print "Year: $year, Week: $w, ($size Subs)\n";
        if ($size == 0) {
            print "\tNo Subs this week.\n\n";
            next;
        }
        $total_subs += $size;
        $year_subs += $size;
        foreach my $pn (sort keys %s) {
            print "\t$pn for $s{$pn}\n";
            $ss{$pn}++;
        }
        print "\n";
    }
    print "$year: Total subs $year_subs\n\n\n";
    $total_years++;
}

print "Total subs = $total_subs, Number of weeks = $num_weeks, Number of years = $total_years\n";
printf("Average subs = %.2f\n", ($total_subs / $num_weeks));

print "\n\n";

foreach my $pn (reverse sort { $ss{$a} <=> $ss{$b} } (keys(%ss))) {
    if ($ss{$pn} > 9) {
        print "$pn: $ss{$pn}\n";
    }
}
