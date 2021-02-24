#!/usr/bin/perl -w
use strict;
use File::Basename;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM [NUM] [FILE...]
";

if (@ARGV and $ARGV[0] =~ /^\d+$/) {
    system "head -n @ARGV";
} else {
    system "head @ARGV";
}
