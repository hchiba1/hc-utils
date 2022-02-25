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

my $SCRIPT = "$ENV{HOME}/github/sivel/speedtest-cli/speedtest.py";
if (!-f $SCRIPT) {
    system "github -prh sivel/speedtest-cli";
}
my $COMMAND = "python3 $SCRIPT";

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
        printf "Date       Time      %-11s%-15s%-15s%-29sServer\n", "Ping", "Download", "Upload", "IP";
    }
    my $count = 0;
    while (1) {
        my $date_time = `date '+%F %T'`;
        chomp($date_time);
        my @line = `$COMMAND $SERVER_OPT`;
        printf "$date_time  %-11s%-15s%-15s%s  %s\n", extract_speed(@line);
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
        if (/^Testing from (.+)\.\.\.$/) {
            printf " %s", $1;
        } elsif (/^Hosted by (.*): (\S+ \S+)$/) {
            print "\n$1\n";
            printf "Ping     %10s\n", $2;
        } elsif (/^Download: (\S+ \S+)$/) {
            printf "Download %14s\n", $1;
        } elsif (/^Upload: (\S+ \S+)$/) {
            printf "Upload   %14s\n", $1;
        }
    }
    close(PIPE) || die;
}

################################################################################
### Functions ##################################################################
################################################################################
sub extract_speed {
    my @line = @_;
    
    my ($ping, $download, $upload, $ip, $server);
    for my $line (@line) {
        if ($line =~ /^Hosted by (.*): (\S+ \S+)$/) {
            $server = $1;
            $ping = $2;
        } elsif ($line =~ /^Testing from (.+)\.\.\.$/) {
            $ip = $1;
        } elsif ($line =~ /^Download: (.*)/) {
            $download = $1;
        } elsif ($line =~ /^Upload: (.*)/) {
            $upload = $1;
        }
    }

    return ($ping, $download, $upload, $ip, $server);
}

sub extract_server {
    my ($pattern) = @_;
    
    my @list = `$COMMAND --list 2>&1`;

    my $number = "";
    for my $server (@list) {
        if ($server =~ /^\s*(\d+)\) +.*$pattern.*/i) {
            $number = $1;
            last;
        }
    }

    if ($number !~ /^\d+$/) {
        die "ERROR: cannot find sever matching '$pattern'\n";
    }

    return $number;
}
