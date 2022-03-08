#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

my %OPT;
getopts('', \%OPT);

!@ARGV && -t and die $USAGE;
my $CURRENT = "";
my $PRINTED = 0;
while (<>) {
    chomp;
    $PRINTED = print_current_or_next($CURRENT, $_);
    $CURRENT = $_;
}
if ($PRINTED == 0) {
    print $CURRENT;
}

################################################################################
### Functions ##################################################################
################################################################################
sub print_current_or_next {
    my ($current, $next) = @_;

    if ($current eq "") {
        return 0;
    }

    if ($current =~ /^[*|\/ \\]+ \([0-9a-f]{7}\)\s+\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \S{5}\] /) {
        print $current, "\n";
        return 1;
    }

    if ($next =~ /^[*|\/ \\]+ \([0-9a-f]{7}\)\s+\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \S{5}\] /) {
        if ($current =~ /^([*|\/ \\]+)\w?.*$/) {
            print $1, "\n"; # print bar only
            return 1;
        } else {
            die;
        }
    }

    if ($current =~ /^([*|\/ \\]+)(.*)$/) {
        my ($current_bar, $current_comment) = ($1, $2);
        if ($current_comment eq "") {
            $current_bar .= " ";
        }
        if ($next =~ /^[*|\/ \\]+(.*)$/) {
            # print next comment
            print $current_bar, $1, "\n";
            return 2;
        } else {
            # print $current, "\n";
            # return 1;
            die;
        }
    }

    die $current;
}
