#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM PROGRAM/PARAM
";

my %OPT;
getopts('', \%OPT);

STDOUT->autoflush;

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}

if ($ARGV[0] =~ /^(\S+?)\/(.+)/) {
    my $cgi_program = $1;
    my $param = $2;
    my $cgi_path = abs_path($cgi_program);
    my $path_info = "/$param";
    system "PATH_INFO=$path_info $cgi_path";
}
