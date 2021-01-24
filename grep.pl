#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM REGEXP [FILE]
-i: ignore case
-v: invert match
-h: output 1st line as header
";

my %OPT;
getopts('ivh', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my $PATTERN = shift @ARGV;

while (<>) {
    if ($OPT{h}) {
        if ($. == 1) {
            print;
        }
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
