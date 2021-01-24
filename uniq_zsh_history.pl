#!/usr/bin/perl -w
use strict;
use File::Basename;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

!@ARGV && -t and die $USAGE;
my %HASH = ();
while (<>) {
    if (/^(\S+ \S+)  (.*)/) {
        my ($date, $command) = ($1, $2);
        if (!$HASH{$command}) {
            $HASH{$command} = 1;
            print "$date  $command\n";
        }
    }
}
