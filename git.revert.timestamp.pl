#!/usr/bin/perl -w
use strict;

my %ls = ();
$/ = "\0";
open FH, 'git ls-files -z|' or die $!;
while (<FH>) {
    chomp;
    $ls{$_} = $_;
}
close FH;

my $commit_time;
$/ = "\n";
open FH, "git log -m -r --name-only --no-color --pretty=raw -z @ARGV |" or die $!;
while (<FH>) {
    chomp;
    if (/^committer .*? (\d+) (?:[\-\+]\d+)$/) {
        $commit_time = $1;
    } elsif (s/\0\0commit [a-f0-9]{40}( \(from [a-f0-9]{40}\))?$// or s/\0$//) {
        my @files = delete @ls{split(/\0/, $_)};
        @files = grep { defined $_ } @files;
        next unless @files;
        utime $commit_time, $commit_time, @files;
    }
    last unless %ls;
}
close FH;
