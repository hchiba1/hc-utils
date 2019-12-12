#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-l: list servers
-S ID: specify server ID
-s SEC: sleep SEC seconds until next trial
-n N: try N trials
-v: verbose
-V: verbose (original command output)
-o 'ARGS': original command with ARGS
-q: print command and quit
-H: do not print header line
";
# -N ID: grep server ID

$|=1; # buffering: off

my %OPT;
getopts('lS:s:n:vVo:qHN:', \%OPT);

my $COMMAND = "$ENV{HOME}/github/sivel/speedtest-cli/speedtest.py";
if (!-f $COMMAND) {
    system "github -prh sivel/speedtest-cli";
}

if ($OPT{q}) {
    print "$COMMAND\n";
    exit;
}

if ($OPT{o}) {
    system "$COMMAND $OPT{o}";
    exit;
}

### Selecte server ###
if ($OPT{l}) {
    system "$COMMAND --list";
    exit;
}

if ($OPT{N}) {
    system "$COMMAND --list | grep -iw '$OPT{N}'";
    exit;
}

my ($SERVER_ID, $SERVER_DESC);
if ($OPT{S}) {
    $SERVER_ID = $OPT{S};
    $SERVER_DESC = select_server($SERVER_ID);
} else {
    ($SERVER_ID, $SERVER_DESC) = extract_server("OPEN Project .*");
    # ($SERVER_ID, $SERVER_DESC) = extract_server(".*Tokyo.*");
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
        printf "Date       Time      %-11s%-15sUpload\n", "Ping", "Download";
    }
    my $count = 0;
    while (1) {
        my $date_time = `date '+%F %T'`;
        chomp($date_time);
        my @line = `$COMMAND --server $SERVER_ID --simple`;
        printf "$date_time  %-11s%-15s%s\n", extract_speed(@line);
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
    my @line = `$COMMAND --server $SERVER_ID --simple`;
    my ($ping, $download, $upload) = extract_speed(@line);

    printf "Ping     %10s\n", $ping;
    printf "Download %14s\n", $download;
    printf "Upload   %14s\n", $upload;
}

################################################################################
### Functions ##################################################################
################################################################################
sub extract_speed {
    my @line = @_;
    
    my ($ping, $download, $upload);
    for my $line (@line) {
        if ($line =~ /^Ping: (.*)/) {
            $ping = $1;
        } elsif ($line =~ /^Download: (.*)/) {
            $download = $1;
        } elsif ($line =~ /^Upload: (.*)/) {
            $upload = $1;
        }
    }

    return ($ping, $download, $upload);
}

sub extract_server {
    my ($pattern) = @_;
    
    my @list = `$COMMAND --list 2>&1`;

    my $number = "";
    my $description = "";
    for my $server (@list) {
        if ($server =~ /^\s*(\d+)\) +($pattern)/) {
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
        if ($server =~ /^\s*$number\) +(\S.*)/) {
            $description = $1;
            last;
        }
    }

    if ($description eq "") {
        die @list;
    }

    return ($description);
}
