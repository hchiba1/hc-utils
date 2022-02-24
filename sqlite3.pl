#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
use DBI;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

my %OPT;
getopts('Tt:C:q', \%OPT);

if (!@ARGV) {
    print STDERR $USAGE;
    exit 1;
}
my ($DB) = @ARGV;

my $QUERY;
if ($OPT{T}) {
    $QUERY = 'select name from sqlite_master where type="table"';
} elsif ($OPT{C}) {
    $QUERY = "select count(*) from $OPT{C}";
} elsif ($OPT{t}) {
    $QUERY = "select * from $OPT{t} limit 10";
} else {
    $QUERY = <STDIN>;
}

if ($OPT{q}) {
    print $QUERY, "\n";
    exit;
}

my $dbh = DBI->connect("dbi:SQLite:dbname=$DB");
my $sth = $dbh->prepare($QUERY);
$sth->execute();
while (my @row = $sth->fetchrow_array) {
    print join("\t", @row), "\n";
}
$sth->finish;
$dbh->disconnect;
