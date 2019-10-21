#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

my %OPT;
getopts('a', \%OPT);

my @LINE = `cat /proc/meminfo`;
if ($OPT{a}) {
    print @LINE;
    exit(1);
}

chomp(@LINE);

my %LEN = ();
my %VAL = ();
for my $line (@LINE) {
    my @f = split(/ +/, $line);
    if (@f == 3) {
	my ($name, $value, $unit) = @f;
	if ($unit eq "kB") {
	    if ($value eq "0") {
		update_len("name", $name);
		update_len("value", "0G");
		$VAL{$name} = "0";
	    } else {
		my $giga = format_size($value);
		update_len("name", $name);
		update_len("value", "${giga}G");
		$VAL{$name} = $giga;
	    }
	}
    }
}

my @FREE = `free`;
chomp(@FREE);
my ($mem, $total, $used, $free, $shared, $buff_cache, $available) = split(/ +/, $FREE[1]);
print_var_name_and_value("Total:", $total);
print_var_name_and_value("Used:", $used);
# print_var_name_and_value("Free:", $free);
# print_var_name_and_value("Shared:", $shared);
# print_var_name_and_value("Buff/Cache:", $buff_cache);
print_var_name_and_value("Available:", $available);
print "\n";

for my $line (@LINE) {
    my @f = split(/ +/, $line);
    if (@f == 3) {
	my ($name, $value, $unit) = @f;
	if ($unit eq "kB") {
	    if ($value eq "0") {
		print_and_padding("name", $name);
		print " ";
		padding_and_print("value", "0G");
		print "\n";
	    } else {
		my $giga = format_size($value);
		print_and_padding("name", $name);
		print " ";
		padding_and_print("value", "${giga}G");
		print "\n";
	    }
	} else {
	    print $line, "\n";
	}
    } else {
	print $line, "\n";
    }
}


################################################################################
### Function ###################################################################
################################################################################

sub format_size {
    my ($kilo) = @_;

    my $giga = $kilo / 1024 / 1024;

    return substr(sprintf("%f", $giga), 0, 5);
}

sub update_len {
    my ($column, $value) = @_;

    my $len = length($value);
    if (!$LEN{$column} || $LEN{$column} < $len) {
	$LEN{$column} = $len;
    }
}

sub padding_and_print {
    my ($name, $value) = @_;

    if (length($value) > $LEN{$name}) {
	die "$name($LEN{$name}):$value";
    }
    
    my $pad_len = $LEN{$name} - length($value);
    print " " x $pad_len . $value;
}

sub print_and_padding {
    my ($name, $value) = @_;

    if (length($value) > $LEN{$name}) {
	die "$name($LEN{$name}):$value";
    }
    
    my $pad_len = $LEN{$name} - length($value);
    print $value . " " x $pad_len;
}

sub print_var_name_and_value {
    my ($name, $value) = @_;

    print_and_padding("name", $name);
    print " ";
    padding_and_print("value", format_size($value)."G");
    print "\n";
    
}
