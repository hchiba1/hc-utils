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
my $BUFFER = "";
my $PRINTED = 0;
while (<>) {
    chomp;
    $PRINTED = print_buffer_or_next($BUFFER, $_);
    $BUFFER = $_;
}
if ($PRINTED == 0) {
    print $BUFFER;
}

################################################################################
### Functions ##################################################################
################################################################################
sub print_buffer_or_next {
    my ($buffer, $next) = @_;

    if ($buffer eq "") {
        return 0;
    }

    if ($buffer =~ /^[*|\/ \\]+ \([0-9a-f]{7}\)\s+\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \S{5}\] /) {
        print $buffer, "\n";
        return 1;
    }

    if ($next =~ /^[*|\/ \\]+ \([0-9a-f]{7}\)\s+\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \S{5}\] /) {
        if ($buffer =~ /^([*|\/ \\]+)\w?.*$/) {
            print $1, "\n"; # print bar only
            return 1;
        } else {
            die;
        }
    }

    if ($buffer =~ /^([*|\/ \\]+)(.*)$/) {
        my ($bar, $comment) = ($1, $2);
        if ($comment eq "") {
            $bar .= " ";
        }
        if ($next =~ /^[*|\/ \\]+(.*)$/) {
            # print next comment
            print $bar, $1, "\n";
            return 2;
        } else {
            # print $buffer, "\n";
            # return 1;
            die;
        }
    }

    die $buffer;
}
