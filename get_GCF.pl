#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
use HTTP::Date 'str2time', 'time2iso';
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM URL
-c: check only
";

my $COMMAND = "curl --max-time 100000 -LfsS";

my %OPT;
getopts('c', \%OPT);

### get URL
if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($URL) = @ARGV;
$URL =~ s/^https:\/\///;

if ($URL =~ /(GCF_\S+)$/) {
    if (-f "${1}_protein.faa.gz") {
        my $local_time = get_local_time("${1}_protein.faa.gz");
        my $local_size = get_local_size("${1}_protein.faa.gz");
        check_update("${1}_protein.faa.gz", $local_time, $local_size);
    } elsif (-f "${1}_protein.faa") {
        my $local_time = get_local_time("${1}_protein.faa");
        my $local_size = get_local_size("${1}_protein.faa");
        check_update("${1}_protein.faa.gz", $local_time, $local_size);
    } else {
        print "Download: ${1}_protein.faa.gz\n";
        if (!$OPT{c}) {
            system "$COMMAND -OR $URL/${1}_protein.faa.gz";
        }
    }
} else {
    print STDERR "ERROR: $URL is not a valid GCF\n";
    exit 1;
}

################################################################################
### Function ###################################################################
################################################################################

sub check_update {
    my ($filename, $local_time, $local_size) = @_;

    my $ftp_time = `ftp.time $URL/ $filename`;
    chomp($ftp_time);
    $ftp_time = time2iso(str2time($ftp_time, "GMT"));
    if ($local_time eq $ftp_time) {
        print "Already updated: $filename\n";
    } else {
        print "Update $filename: $local_time => new $ftp_time\n";
        if (!$OPT{c}) {
            system "$COMMAND -OR $URL/$filename";
        }
    }
}

sub get_local_time {
    my ($file) = @_;

    my @stat = stat $file;
    my $time = time2iso($stat[9]);

    return $time;
}

sub get_local_size {
    my ($file) = @_;

    my @stat = stat $file;

    return $stat[7];
}
