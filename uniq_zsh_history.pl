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
my %HASH = ();
while (<>) {
    chomp;
    if (/^(\S+ \S+)  (.*)$/) {
        my ($date, $command) = ($1, $2);
        if ($HASH{$command}) {
        } else {
            $HASH{$command} = 1;
            print "$date  $command\n";
        }
    }
}
