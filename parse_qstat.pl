#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-a: all queue
-H: without header
-l: output lines
";

my %OPT;
getopts('aHl', \%OPT);

my @line = <STDIN>;

if ($OPT{l} && !$OPT{H}) {
    print @line[0..4];
}

chomp(@line);

my $bar = $line[4];

my @field = split(" ", $bar);

my $n_field = @field;

my @field_len = ();
for (my $j=0; $j<@field; $j++) {
    $field_len[$j] = length($field[$j]);
}

my @field_start = (0);
for (my $j=1; $j<@field; $j++) {
    $field_start[$j] = $field_start[$j-1] + $field_len[$j-1] + 1;
}

my %HASH = ();
my %STATUS = ();
my %QUEUE = ();
for (my $i=5; $i<@line; $i++) {
    my $user = extract_field($line[$i], 1);
    my $queue = extract_field($line[$i], 2);
    my $status = extract_field($line[$i], 9);
    if (@ARGV) {
        if ($line[$i] !~ $ARGV[0]) {
            next;
        }
    }
    if ($OPT{l}) {
        print "$line[$i]\n";
    }
    $queue =~ s/ +$//;
    $QUEUE{$queue}++;
    $STATUS{$status} = 1;
    $HASH{$queue}{$user}{$status}++;
}

if ($OPT{l}) {
    exit;
}

my $N_STATUS = 0;
for my $status (keys %STATUS) {
    $N_STATUS++;
}
for my $queue (sort keys %HASH) {
    if (!$OPT{a}) {
        if ($queue eq "db" || $queue eq "blast") {
            next;
        }
    }
    print "--- $queue " . "-" x (11 - length($queue) + $N_STATUS * 7) . "\n";
    for my $user (sort keys %{$HASH{$queue}}) {
        print "$user";
        for my $status (sort {$b cmp $a} keys %STATUS) {
            my $count = 0;
            print "|$status ";
            if ($HASH{$queue}{$user}{$status}) {
                $count = $HASH{$queue}{$user}{$status};
                printf "%4d", $count;
            } else {
                print "    ";
            }
        }
        print "|\n";
    }
    print "\n";
}

################################################################################
### Function ###################################################################
################################################################################

sub extract_field {
    my ($line, $j) = @_;

    my $out = substr($line, $field_start[$j], $field_len[$j]);

    return $out;
}
