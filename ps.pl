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
-l: show ledgends
-P: show PPID
-M: show %MEM
-V: show VIRT
-W: show WCHAN
-E: show environment variables for each command line
-T: do not show time
-s: do not show tree
-t: use tab as column delimiter
";

my %OPT;
getopts('dmalPMVWETst', \%OPT);

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
my %PARENT_CHILD = ();
my %PROCESS = ();
my %LEN = ();
for my $line (@LINE) {
    my $pid = extract_and_save_columns($line);
    sava_info($pid, "START", extract_start($line));
    sava_info($pid, "COMMAND", extract_command($line));
}

### Select ###
my %SELECTED = ();
if (@ARGV) {
    %LEN = ();
    %CHILD = ();
    %PARENT_CHILD = ();
    update_columns_lengths("PID");
    for my $pid (keys %PROCESS) {
        contains_keyword($pid, @ARGV) and select_pid($pid);
    }
}

### Print ###
print_columns("PID", "");
print_process_rec(1, "", 0);
print_process_rec(2, "", 0) if $OPT{a};
print_ledgends() if $OPT{l};

################################################################################
### Function ###################################################################
################################################################################

sub contains_keyword {
    my ($pid, @argv) = @_;

    my $keyword = $argv[0];

    if ($PROCESS{$pid}{COMMAND} =~ /$keyword/i ||
        $PROCESS{$pid}{USER} =~ /$keyword/i) {
        return 1;
    }

    return 0;
}

sub select_pid {
    my ($pid) = @_;

    if ($pid eq $$ || $PROCESS{$pid}{PPID} eq $$) {
        return;
    }

    $SELECTED{$pid} = 1;
    update_columns_lengths($pid);
    while ($PARENT{$pid}) {
        add_child($PARENT{$pid}, $pid);
        $pid = $PARENT{$pid};
        $SELECTED{$pid} = 1;
        update_columns_lengths($pid);
    }
}

sub update_columns_lengths {
    my ($pid) = @_;

    my @col_name = ("PPID", "PID", "CPU", "MEM", "PHYS", "VIRT", "STAT", "WCHAN", "START", "TIME", "TTY", "USER");
    for my $col_name (@col_name) {
        update_max_len($col_name, $PROCESS{$pid}{$col_name});
    }
}

sub print_process_rec {
    my ($pid, $pad, $last_child) = @_;

    $pid eq $$ and return;                 # this process
    @ARGV && !$SELECTED{$pid} and return;  # did not match keyword
    
    my $ppid = $PROCESS{$pid}{PPID};
    if ($pid eq "1") {                     # pid=1 is a special process
        if (!@ARGV or contains_keyword($pid, @ARGV)) {
            print_columns($pid, "");
        }
    } elsif ($ppid eq "0" || $ppid eq "1") { # pid=1,2 || children of pid=1
        print_columns($pid, "");
    } elsif ($OPT{s}) {
        print_columns($pid, "");
    } elsif ($last_child) {
        print_columns($pid, "${pad}`- ");
    } else {
        print_columns($pid, "${pad}|- ");
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

sub print_columns {
    my ($pid, $tree) = @_;
    
    print_column($pid, "PPID", "right") if $OPT{P};
    print_column($pid, "PID", "right");
    print_column($pid, "CPU", "right");
    print_column($pid, "MEM", "right") if $OPT{M};
    print_column($pid, "PHYS", "right");
    print_column($pid, "VIRT", "right") if $OPT{V};
    print_column($pid, "STAT", "left");
    print_column($pid, "WCHAN", "left") if $OPT{W};
    print_column($pid, "START", "left") if !$OPT{T};
    print_column($pid, "TIME", "right") if !$OPT{T};
    print_column($pid, "TTY", "left");
    print_column($pid, "USER", "left");
    print $tree if $tree;
    print $PROCESS{$pid}{COMMAND}, "\n";
}

sub print_column {
    my ($pid, $col_name, $align) = @_;

    my $val = $PROCESS{$pid}{$col_name};

    print($val) if $align eq "left";
    if (!$OPT{t}) {
        print(" " x ($LEN{$col_name} - length($val))) if $LEN{$col_name} > length($val);
    }
    print($val) if $align eq "right";
    if ($OPT{t}) {
        print "\t";
    } else {
        print " ";
    }
}

sub extract_and_save_columns {
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

    if ($PARENT_CHILD{$parent}{$child}) {
        return;
    }
    $PARENT_CHILD{$parent}{$child} = 1;

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
    print "-sleep, L locked, 1 leader, =multi, *fore";
    print "\n";
}
