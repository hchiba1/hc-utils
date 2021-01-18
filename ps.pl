#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
-d: debug
-m: show threads in multiple lines
-a: show kernel threads too
-t: do not show time
-P: show PPID
-M: show %MEM
-V: show VIRT
-W: show WCHAN
-E: show environment variables for each command line
";

my %OPT;
getopts('dmatPMVWE', \%OPT);

### Execute ###
my $PS_OPT = "";
$PS_OPT .= "e" if $OPT{E};
$PS_OPT .= "M" if $OPT{m};
$PS_OPT .= " -A -o ppid,pid,pcpu,pmem,rss,vsz,tty,stat,wchan,user,time,lstart,command";
# stime or lstart
# bsdtime or time

if ($OPT{d} || $OPT{m}) {
    system "ps $PS_OPT | less -S";
    exit(1);
}
my @LINE = `ps $PS_OPT`;
chomp(@LINE);

my $YEAR = `date "+%Y"`;
chomp($YEAR);

my %MONTH_INT = ( Jan => 1, Feb => 2, Mar => 3, Apr => 4, May => 5, Jun => 6,
                  Jul => 7, Aug => 8, Sep => 9, Oct =>10, Nov =>11, Dec =>12 );

### Parse ###
my %POS = ();
parse_header_column_pos($LINE[0]);

my %PARENT = ();
my %CHILD = ();
my %PROCESS = ();
my %LEN = ();
for my $line (@LINE) {
    my $pid = extract_columns($line);
    my $start = extract_start($line);
    sava_info($pid, "START", $start);
    my $command = extract_command($line);
    sava_info($pid, "COMMAND", $command);
}

### Print ###
print_process_meta_data("PID");
print $PROCESS{"PID"}{COMMAND};
print "\n";

my %FLAG = (); # Set flags for print, if keyword specified.
if (@ARGV) {
    for my $pid (keys %PROCESS) {
        next if ($pid eq $$ || $PROCESS{$pid}{PPID} eq $$);
        if (process_contains_keyword($pid, @ARGV)) {
            trace_back($pid);
        }
    }
}
print_process_rec(1, "", 0);
print_process_rec(2, "", 0) if $OPT{a}; # kernel threads
print_ledgends();

################################################################################
### Function ###################################################################
################################################################################

sub process_contains_keyword {
    my ($pid, @argv) = @_;

    if (!@argv) {
        return 1;
    }

    my $keyword = $argv[0];
    if ($PROCESS{$pid}{COMMAND} =~ /$keyword/i ||
        $PROCESS{$pid}{USER} =~ /$keyword/i) {
        return 1;
    } else {
        return 0;
    }
}

sub trace_back {
    my ($pid) = @_;

    $FLAG{$pid} = 1;
    while ($PARENT{$pid}) {
        $pid = $PARENT{$pid};
        $FLAG{$pid} = 1;
    }
}

sub print_process_rec {
    my ($pid, $pad, $last_child) = @_;
    my $ppid = $PROCESS{$pid}{PPID};

    if (@ARGV && !$FLAG{$pid} || # did not match keyword
        $pid eq $$) {            # this process
        return;                  # do not show
    }
    
    if ($pid eq "1") { # pid=1 is a special process
        if (process_contains_keyword($pid, @ARGV)) { # hide it when it does not match keyword
            print_process_meta_data($pid);
            print $PROCESS{$pid}{COMMAND};
            print "\n";
        }
    } elsif ($ppid eq "0" || $ppid eq "1") { # pid=1,2 || children of pid=1
        print_process_meta_data($pid);
        print $PROCESS{$pid}{COMMAND};
        print "\n";
    } else {
        print_process_meta_data($pid);
        if ($last_child) {
            print $pad . "`- " . $PROCESS{$pid}{COMMAND};
        } else {
            print $pad . "|- " . $PROCESS{$pid}{COMMAND};
        }
        print "\n";
    }
    
    if ($CHILD{$pid}) {
        my @child = @{$CHILD{$pid}};
        for (my $i=0; $i<@child; $i++) {
            my $next_pad = "";
            if ($ppid == 0 || $ppid == 1) {
                $next_pad = "";
            } else {
                if ($last_child) {
                    $next_pad = $pad . "   ";
                } else {
                    $next_pad = $pad . "|  ";
                }
            }
            my $last_child = 0;
            if ($i == @child - 1) {
                $last_child = 1;
            }
            print_process_rec($child[$i], $next_pad, $last_child);
        }
    }
}

sub print_process_meta_data {
    my ($pid) = @_;
    
    print_column($pid, "PPID", "right") if $OPT{P};
    print_column($pid, "PID", "right");
    print_column($pid, "CPU", "right");
    print_column($pid, "MEM", "right") if $OPT{M};
    print_column($pid, "PHYS", "right");
    print_column($pid, "VIRT", "right") if $OPT{V};
    print_column($pid, "STAT", "left");
    print_column($pid, "WCHAN", "left") if $OPT{W};
    if (!$OPT{t}) {
        print_column($pid, "START", "left");
        print_column($pid, "TIME", "right");
    }
    print_column($pid, "TTY", "left");
    print_column($pid, "USER", "left");
}

sub print_column {
    my ($pid, $col_name, $align) = @_;

    my $val = $PROCESS{$pid}{$col_name};

    print($val) if $align eq "left";
    print(" " x ($LEN{$col_name} - length($val))) if $LEN{$col_name} > length($val);
    print($val) if $align eq "right";
    print " ";
}

sub extract_columns {
    my ($line) = @_;
    $line =~ s/^ +//;

    my ($ppid, $pid, $cpu, $mem, $phys, $virt, $tty, $stat, $wchan, $user, $time) = split(/ +/, $line);
    $PARENT{$pid} = $ppid;
    add_child($ppid, $pid);

    if ($mem !~ /%/) {
        $mem .= "%";
    }
    if ($cpu !~ /%/) {
        $cpu .= "%";
    }
    
    if ($phys eq "0") {
    } elsif ($phys =~ /\d+/) {
        $phys = format_size($phys) . "G";
    } else {
        $phys = "PHYS";
    }
    if ($virt eq "0") {
    } elsif ($virt =~ /\d+/) {
        $virt = format_size($virt) . "G";
    } else {
        $virt = "VIRT";
    }

    if ($tty eq "TT") {
        $tty = "TTY";
    }

    if ($stat ne "STAT") {
        $stat =~ s/</>/; #high-priority
        $stat =~ s/N/</; #low-priority
        $stat =~ s/\+/*/; #foreground
        $stat =~ s/\+/!/; #foreground
        $stat =~ s/S/-/; #sleep
        $stat =~ s/D/O/; #IO
        $stat =~ s/l/=/; #multi-thread
        $stat =~ s/s/1/; #session leader
    }

    $time =~ s/^00://;
    $time =~ s/^0(\d:)/$1/;
    
    sava_info($pid, "PPID", $ppid);
    sava_info($pid, "PID", $pid);
    sava_info($pid, "CPU", $cpu);
    sava_info($pid, "MEM", $mem);
    sava_info($pid, "PHYS", $phys);
    sava_info($pid, "VIRT", $virt);
    sava_info($pid, "TTY", $tty);
    sava_info($pid, "STAT", $stat);
    sava_info($pid, "WCHAN", $wchan);
    sava_info($pid, "USER", $user);
    sava_info($pid, "TIME", $time);

    return $pid;
}

sub add_child {
    my ($parent, $child) = @_;

    if ($CHILD{$parent}) {
        push @{$CHILD{$parent}}, $child;
    } else {
        $CHILD{$parent} = [$child];
    }
}

sub format_size {
    my ($kilo) = @_;

    if ($kilo eq "0") {
        return "0";
    }

    my $giga = $kilo / 1024 / 1024;

    return substr(sprintf("%f", $giga), 0, 5);
}

sub sava_info {
    my ($pid, $name, $val) = @_;

    $PROCESS{$pid}{$name} = $val;
    update_max_len($name, $val);
}

sub update_max_len {
    my ($name, $value) = @_;

    if (!$LEN{$name} || length($value) > $LEN{$name}) {
        $LEN{$name} = length($value);
    }
}

sub extract_start {
    my ($line) = @_;
    
    my $start = substr($line, $POS{TIME}{end});
    $start =~ s/^\S+//; # clear previous column
    $start =~ s/^ +//;  # clear padding

    if ($start =~ /^(START\S+)/) { # header line
        return $1;
    } elsif ($start =~ /^[A-Z][a-z][a-z] ([A-Z][a-z][a-z]) (.\d) (\d\d:\d\d:\d\d) (\d+).*/) {
        my ($month, $day, $time, $year) = ($1, $2, $3, $4);
        if ($MONTH_INT{$month}) {
            $month = $MONTH_INT{$month};
            if ($YEAR eq $year) {
                return sprintf("%02d-%02d %s", $month, $day, $time);
            } else {
                return sprintf("%d-%02d-%02d %s", $year, $month, $day, $time);
            }
        }
    }

    return $start;
}

sub extract_command {
    my ($line) = @_;

    my $command = substr($line, $POS{COMMAND}{start}-1);
    $command =~ s/^\S*//;
    $command =~ s/^ +//;

    return $command;
}

sub parse_header_column_pos {
    my ($header) = @_;
    
    my @field = split(/ +/, $header);
    for (my $i=0; $i<@field; $i++) {
        my ($start, $end) = get_column_pos($header, $field[$i]);
        $POS{$field[$i]}{start} = $start;
        $POS{$field[$i]}{end} = $end;
        $POS{$field[$i]}{length} = $end - $start + 1;
        $POS{$field[$i]}{colnum} = $i;
    }
}

sub get_column_pos {
    my ($line, $column) = @_;
    
    if ($line =~ /^((.*)$column)/) {
        my $start_pos = length($2);
        my $end_pos = length($1);
        return ($start_pos, $end_pos);
    } else {
        die "cannot found $column";
    }
}

sub print_ledgends {
    print "\n";
    # print "- sleep, L locked, 1 session leader, = multi-threaded, * foreground";
    print "-sleep, 1 leader, =multi, *fore";
    print "\n";
}
