#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM REGEXP [FILE]
-i: ignore case
-v: invert match
-1: output 1st line as header
-2: output 2nd line as header
";

my %OPT;
getopts('iv12', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my $PATTERN = shift @ARGV;

while (<>) {
    if ($OPT{1} && $. == 1) {
        print;
    }
    if ($OPT{2} && $. == 2) {
        print;
    }

    if (isMatched($_, $PATTERN)) {
        if (@ARGV >= 2) {
            print "$ARGV:";
        }
        print;
    }
}

################################################################################
### Function ###################################################################
################################################################################

sub isMatched {
    my ($str, $pattern) = @_;

    my $bool = 0;
    if ($OPT{i}) {
	if ($str =~ /$pattern/i) {
	    $bool = 1;
	}
    } else {
        if ($str =~ /$pattern/) {
            $bool = 1;
        }
    }

    if ($OPT{v}) {
        $bool = ! $bool;
    }
    
    return $bool;
}
