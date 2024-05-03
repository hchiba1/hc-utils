#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
use HTTP::Date 'str2time', 'time2iso';
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM URL
";

my $COMMAND = "curl --max-time 100000 -LfsS";

my %OPT;
getopts('', \%OPT);

### get URL
if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($URL) = @ARGV;
$URL =~ s/^https:\/\///;

if ($URL =~ /(GCF_\S+)$/) {
    my $filename = "${1}_protein.faa.gz";
    if (-f $filename) {
        check_update($filename);
    } else {
        system "$COMMAND -OR $URL/$filename";
    }
} else {
    print STDERR "ERROR: $URL is not a valid GCF\n";
    exit 1;
}

################################################################################
### Function ###################################################################
################################################################################

sub check_update {
    my ($filename) = @_;

    my $local_day = get_local_day($filename);
    my $local_size = get_local_size($filename);

    my $ftp_time_size = `ftp.time $URL/ $filename`;
    chomp($ftp_time_size);
    my @ftp_time_size = split(/\t/, $ftp_time_size, -1);
    if (@ftp_time_size != 2) {
        print "ERROR: $ftp_time_size\n";
        exit 1;
    }
    my ($day, $size) = @ftp_time_size;
    $day = time2iso(str2time($day, "GMT"));
    if ($local_day eq $day && $local_size eq $size) {
        print "Already updated: $filename\n";
    } else {
        if ($local_day ne $day) {
            print "Update $filename: $local_day => new $day\n";
        }
        if ($local_size ne $size) {
            print "Update $filename: $local_size => new $size\n";
        }
        system "$COMMAND -OR $URL/$filename";
    }
}

sub get_local_day {
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
