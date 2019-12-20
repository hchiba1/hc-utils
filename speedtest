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
-v: verbose
-V: verbose (original command output)
-o 'ARGS': original command with ARGS
-H: do not print header line
";

$|=1; # buffering: off

my %OPT;
getopts('ls:n:vVo:H', \%OPT);

my $COMMAND = "speedtest-go";

if ($OPT{o}) {
    system "$COMMAND $OPT{o}";
    exit;
}

### Selecte server ###
if ($OPT{l}) {
    system "$COMMAND --list";
    exit;
}

my ($SERVER_ID, $SERVER_DESC);
if (!@ARGV) {
    ($SERVER_ID, $SERVER_DESC) = extract_server("OPEN Project");
} elsif ($ARGV[0] =~ /^\d+$/) {
    ($SERVER_ID, $SERVER_DESC) = select_server($ARGV[0]);
} else {
    ($SERVER_ID, $SERVER_DESC) = extract_server($ARGV[0]);
}

if ($OPT{v}) {
    print "$SERVER_DESC\n";
}

### Exec ###
if ($OPT{V}) {
    system "$COMMAND --server $SERVER_ID";
} elsif ($OPT{s} || $OPT{n}) {
    my $sleep_seconds = $OPT{s} || 0;
    if (!$OPT{H}) {
        # printf "Date       Time     %11s %14s %14s\n", "Ping", "Download", "Upload";
        printf "Date       Time     %14s %14s %10s\n", "Download", "Upload", "Ping";
    }
    my $count = 0;
    while (1) {
        my $date_time = `date '+%F %T'`;
        chomp($date_time);
        my @line = `$COMMAND --server $SERVER_ID`;
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
    print "$date_time\n";
    my @line = `$COMMAND --server $SERVER_ID`;
    my ($download, $upload, $ping) = extract_speed(@line);

    printf "Ping     %10s\n", $ping;
    printf "Upload   %14s\n", $upload;
    printf "Download %14s\n", $download;
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

    return ($number, $description);
}

sub select_server {
    my ($number) = @_;
    
    my @list = `$COMMAND --list 2>&1`;

    my $description = "";
    for my $server (@list) {
        if ($server =~ /^\[$number\] +\S+ (.*)/) {
            $description = $1;
            last;
        }
    }

    if ($description eq "") {
        die @list;
    }

    return ($number, $description);
}
