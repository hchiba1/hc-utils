#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM REGEXP [FILE]
-i: ignore case
-v: invert match
-w: match word
-1: output 1st line as header
-2: output 2nd line as header
";

my %OPT;
getopts('ivw12', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

my $PATTERN = shift @ARGV;

my $FLG_FILENAME = 0;
if (@ARGV >= 2) {
    $FLG_FILENAME = 1;
}

STDOUT->autoflush;
while (<>) {
    if ($OPT{1} && $. == 1) {
        print;
    }
    if ($OPT{2} && $. == 2) {
        print;
    }

    if (isMatched($_, $PATTERN)) {
        if ($FLG_FILENAME) {
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

    if ($OPT{w}) {
        $pattern = '\b' . $pattern . '\b';
    }

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
