#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM [SERVER_ID|PATTERN]
-l: list servers
-s SEC: sleep SEC seconds until next trial
-n N: try N trials
-H: do not print header line
";

$|=1; # buffering: off

my %OPT;
getopts('ls:n:H', \%OPT);

my $COMMAND = "speedtest-go";

### Selecte server ###
if ($OPT{l}) {
    system "$COMMAND --list";
    exit;
}

my $SERVER_OPT = "";
if (@ARGV) {
    if ($ARGV[0] =~ /^\d+$/) {
        $SERVER_OPT = "--server $ARGV[0]";
    } else {
        $SERVER_OPT = "--server " . extract_server($ARGV[0]);
    }
}

### Exec ###
if ($OPT{s} || $OPT{n}) {
    my $sleep_seconds = $OPT{s} || 0;
    if (!$OPT{H}) {
        # printf "Date       Time     %11s %14s %14s\n", "Ping", "Download", "Upload";
        printf "Date       Time     %14s %14s %10s\n", "Download", "Upload", "Ping";
    }
    my $count = 0;
    while (1) {
        my $date_time = `date '+%F %T'`;
        chomp($date_time);
        my @line = `$COMMAND $SERVER_OPT`;
        printf "$date_time %14s %14s %10s\n", extract_speed(@line);
        $count ++;
        if ($OPT{n} and $OPT{n} == $count) {
            last;
        }
        sleep $sleep_seconds;
    }
} else {
    my $date_time = `date '+%F %T'`;
    chomp($date_time);
    print "$date_time";
    open(PIPE, "$COMMAND $SERVER_OPT|") || die;
    while (<PIPE>) {
        chomp;
        if (/^Testing From IP: (.+)$/) {
            printf " %s\n", $1;
        } elsif (/^Target Server: (\S+)\s+(.*)$/) {
            print "$2 $1\n";
        } elsif (/^Latency: (.*)ms$/) {
            my $ping = sprintf("%.3f ms", $1);
            printf "Ping     %10s\n", $ping;
        } elsif (/^Download: (\S+ \S+)$/) {
            printf "Download %14s\n", $1;
        } elsif (/^Upload: (\S+ \S+)$/) {
            printf "Upload   %14s\n", $1;
        }
    }
}

################################################################################
### Functions ##################################################################
################################################################################
sub extract_speed {
    my @line = @_;
    
    my ($ping, $download, $upload);
    for my $line (@line) {
        if ($line =~ /^Latency: (.*)ms/) {
            # $ping = "$1 ms";
            $ping = sprintf("%.3f ms", $1)
        } elsif ($line =~ /^Download: (.*)/) {
            $download = $1;
        } elsif ($line =~ /^Upload: (.*)/) {
            $upload = $1;
        }
    }

    # return ($ping, $download, $upload);
    return ($download, $upload, $ping);
}

sub extract_server {
    my ($pattern) = @_;
    
    my @list = `$COMMAND --list 2>&1`;

    my $number = "";
    my $description = "";
    for my $server (@list) {
        if ($server =~ /^\[(\d+)\] +\S+ (.*$pattern.*)/i) {
            $number = $1;
            $description = $2;
            last;
        }
    }

    if ($number !~ /^\d+$/) {
        die @list;
    }

    return $number;
}
