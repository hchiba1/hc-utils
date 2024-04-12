#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM URL
-d: directory contents
";

my %OPT;
getopts('d', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($URL) = @ARGV;

$URL =~ s/^https:\/\///;
if ($URL =~ /(GCF_\S+)$/) {
    my $gcf = $1;
    if ($OPT{d}) {
        system "get $URL/";
    } else {
        system "get -f $URL/${gcf}_protein.faa.gz";
    }
} else {
    print STDERR "ERROR: $URL is not a valid GCF\n";
    exit 1;
}
