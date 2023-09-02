#!/usr/bin/perl
=MADE by Twix ::
    https://github.com/Twix53791
    twixgithub@protonmail.com
=====================================
  @ARGV:
    Optionnal: <command> <debug flag>


=====================================
=cut

use strict;
no strict "refs";
use warnings;

use FindBin qw( $RealBin );
use lib $RealBin;
use core::background;
use core::config;
use core::context;
use core::io;
use core::tags;
use commands::show;
use commands::add;
use commands::buildindexes;
use commands::browse;
use commands::delete;
use commands::edit;
use commands::exit;
use commands::export;
use commands::filter;
use commands::readkey;
use commands::searchbytags;
use commands::tag;

=Init =====================
  Sets directory locations
  Parses arguments
  Parses config file
  Sets context
===========================
=cut

=Sets working directories, init files
=====================================
=cut

# Needed to run backgroung tasks
#  from the commands cf. https://duyanghao.github.io/ways_avoid_zombie_process/
$SIG{CHLD}='IGNORE';

my ($FIFO_TO_PL, $FIFO_TO_SH, $CACHE, $USERCONFIG, $TMPDIR) = splice @ARGV, 0, 5;

$USERCONFIG = $RealBin . "/config" if (not -d $USERCONFIG);

my $LOGFILE = "/tmp/papis-fzf/papis-fzf.log";
my $date=localtime();
open my $LOG, ">>", $LOGFILE or die "papis-fzf ERROR :: Can't open $LOGFILE: $!";
    print $LOG "\n=========================================\n";
    printf $LOG "papis-fzf LOG :: Init %s\n", $date;

*STDERR = $LOG; # Redirects STDERR to logfile

## Directories 'usercommands', 'preview'
my $USERCMD    = $USERCONFIG . "/commands";     # lets users add custom commands
my $MODULESDIR = $USERCONFIG . "/modules";   # modules editable by users
my $PREVIEW    = $RealBin . "/core/preview.pm"; # fzf preview script

## Open 'the fifo-in' to listen it via io::fifo_in
open my $FIFO_IN, "+<", $FIFO_TO_PL
    or die "papis-fzf ERROR :: Can't listen the fifo $FIFO_TO_PL: $!";

=Parses arguments
=================
=cut
my ($CMD, $DEBUG) = (0, 0);

foreach (@ARGV) {
    if ($_ eq "-d" or $_ eq "--debug") {
        $DEBUG = 1;
    } elsif ($DEBUG and /^[0-2]$/) {
        $DEBUG = $_;
    } else {
        $_ =~ s/-//g;         # it is possible to run papis-fzf search-by-tags
        if ($_ eq "add" or
            $_ eq "searchbytags" or
            $_ eq "buildindexes" or
            $_ eq "readkey")
        {
            $CMD = $_;
        }
    }
}

shift if ($CMD);
shift if ($DEBUG);

=Config & context objects ================
  These objects are passed to all commands
==========================================
=cut
# Parses config (sets config object)
my $config = parse_config config($USERCONFIG);

# Sets context object
# !!! the order of parameters is important! Do not change it
my $context =
    command_context context(
        $RealBin,
        $FIFO_TO_SH,
        $FIFO_IN,
        $USERCONFIG,
        $CACHE,
        $TMPDIR,
        $LOGFILE,
        $DEBUG,
        $PREVIEW,
        );


=debug output=============
  Prints the values above
==========================
=cut
if ($DEBUG) {
    print "papis-fzf :: DEBUG RealBin : $RealBin\n";
    print "papis-fzf :: DEBUG config dir : $USERCONFIG\n";
    print "papis-fzf :: DEBUG cache dir : $CACHE\n";
    print "papis-fzf :: DEBUG tmp dir : $TMPDIR\n";
    print "papis-fzf :: DEBUG logfile : $LOGFILE\n";
    print "papis-fzf :: DEBUG user commands : $USERCMD\n";
    print "papis-fzf :: DEBUG modules : $MODULESDIR\n";
    print "papis-fzf :: DEBUG command : $CMD\n";
    print "papis-fzf :: DEBUG arguments : @ARGV\n";

    if ($DEBUG == 2) {
        # Parses, sorts & prints context object
        print "====\npapis-fzf :: DEBUG context object :\n\n";
        my @contextarray;
        while((my $key, my $value) = each (%{$context})){
           push @contextarray, "$key -> $value";
        }
        @contextarray = sort { $a cmp $b } @contextarray;
        foreach (@contextarray) {
            print "$_\n";
        }

        # Parses, sorts & prints config object
        print "====\npapis-fzf :: DEBUG config object :\n\n";
        my @configarray;
        while((my $key, my $value) = each (%{$config})){
           push @configarray, "$key -> $value";
        }

        @configarray = sort { $a cmp $b } @configarray;

        foreach (@configarray) {
            print "$_\n";
        }
    }
}


=Modules ==============================
  Loads modules dynamically.
=======================================
=cut
print "====\npapis-fzf :: DEBUG modules loaded :\n\n" if ($DEBUG);

# Source modules directory
my @modules = glob( $RealBin . '/modules/*' );

foreach (@modules) {
    # The module is loaded from userconfig if available
    #  or from the source modules directory if not.
    my $basename = $_ =~ s/.*\///r;
    my $module = "$MODULESDIR/$basename";
    $module = $_ if (not -f $module);

    # Loads module. Debug messages if successes/fails
    my $load = eval "require '$module'; 1";
    if (!$load) {
        print "papis-fzf :: ERROR failed to load $module\n";
    } elsif ($DEBUG) {
        print "$module\n";
    }
}


=User commands ===============================
  Loads user commands (~ plugins) dynamically.
==============================================
=cut
if (-d $USERCMD) {
    print "====\npapis-fzf :: DEBUG user commands loaded :\n\n" if ($DEBUG);

    # Source modules directory
    my @commands = glob( $USERCMD . '/*' );

    foreach (@commands) {
        # The usercmd is loaded from userconfig/commands
        #  if available.

        # Loads module. Debug messages if successes/fails
        my $load = eval "require '$_'; 1";
        if (!$load) {
            print "papis-fzf :: ERROR failed to load $_\n";
        } elsif ($DEBUG) {
            print "$_\n";
        }
    }
}


#====================================================
#==  One run of a command  ==========================
#====================================================
=One run
  If a valid command (cf. Parses arguments above)
   is passed to papis-fzf, runs it ONCE.
  It pursues on the main loop only if the command
   returns a value.
=====================================================
=cut

my $CMDRET;

if ($CMD) {
    # Debug
    if ($DEBUG) {
        print "====\npapis-fzf :: DEBUG one run command : $CMD\n";
        print "papis-fzf :: DEBUG one run arguments : @ARGV\n";
    }

    my $COMMAND      = $CMD . "::" . $CMD;
    $context->{from} = "onerun";            # The cmd will know from where it runs
    $CMDRET          = &$COMMAND($context, $config, @ARGV);

    print "\npapis-fzf :: DEBUG one run command returns : @$CMDRET\n\n" if ($DEBUG);

    if ($CMDRET and @$CMDRET) {             # $CMDRET is an array reference and not empty
        goto MAINLOOP
    } else {
        exit::exit($context);
    }
}


#===========================================================
#==  Main loop  ============================================
#===========================================================
=Main loop of papis-fzf
  -Runs fzf
  -Parses the fzf output
    to get a list of papis-folders
  -Runs command
   # Commands are perl modules
  -Repeats loop (goto)

  NOTE:
  All commands received as arguments the list below:

    <context object> <config object> (list of papis-folders)
============================================================
=cut
#==  command checking  ==============================

sub iscmd {
# @_ : command (string) to check
    my $cmd = shift;
    my $path .= sprintf "%s/commands/%s.pm", $RealBin, $cmd =~ s/^://r;

    return (-f $path) ? 1 : 0;
}

#====================================================

MAINLOOP:

my $fzfindex = "$CACHE/index-colored";

# Resets/initializes values ======================
my ($cmd, $query) = ("", "");
my (@fzfoutput, @fzfselection) = ((), ());
my (@ordinals, @papisfolders);

=Runs fzf  =======================================
  CDMRET is the value returned by commands
  A command can return an array reference (\@array)
   to display a subselection of the papis library
   in the main menu.
==================================================
=cut

# Fzf command (set options)
my @fzfcmd = fzfenv::set_options($context, $config, "main");


=Subselection menu  =================================
  This menu displays a selection of the papis library
   filtered by a previous command (searchbytags, show...)

  All commands MUST return a value : 0 to come back to the
   main menu, an array reference to execute this menu.

  @$CMDRET : "command" @ordinals   # The command is optional.
=cut
if ($CMDRET and @$CMDRET) {
    # 1) evaluates if a command is passed as argument
    my ($cmd, @folders) = @$CMDRET;
    unshift @folders, $cmd and undef $cmd if (not iscmd($cmd));

    # If $cmd AND @_ length of 1, skip the subselection menu
    if ($cmd and $#folders == 0) {
        @fzfoutput = ($cmd, @folders);
        goto RUNCMD;
    }

    # 3) display the given subselection of library entries with fzf
    my $input = sprintf "\"%s\"",
                join "\\n", io::ordinals_to_fzf($CACHE, @folders);
    my $fzf = "echo -en $input | @fzfcmd &";

    io::fifo_out($FIFO_TO_SH, $fzf);
    @fzfoutput = io::fifo_in($FIFO_IN);

    # :exit from the subselection comes back to the main menu
    goto MAINMENU if ($fzfoutput[0] =~ m/:exit/);

    # The second arg of @fzfoutput has priority
    # Passing the command like that force to run it on the subselection
    #  = it 'disables' all main menu key bindings
    splice @fzfoutput, 1, 0, $cmd if ($cmd);

} else {
=Main menu ================================
  This menu displays all the papis library
   references.

  The fzfindex file is a permanent file
   usually only partially updated when needed.
  It can be recreated from scratch with:
      papis-fzf build-indexes

===========================================
=cut
MAINMENU:
    my $fzf = "sort '$fzfindex' | @fzfcmd";

    io::fifo_out($FIFO_TO_SH, $fzf);
    @fzfoutput = io::fifo_in($FIFO_IN);
}

=Parses fzf output, gets $cmd, $query ===================
  NOTE: any key press executing 'accept' in fzf must echo a command
  The fzf output order is:
    `execute(echo ':command')`, --print-query, selection
=========================================================
=cut

# If no output: reruns fzf menu
goto MAINLOOP if (!@fzfoutput);

chomp foreach @fzfoutput; # Gets rid of \n

RUNCMD:
#==  Parse @fzfoutput ========================
($cmd, $query, @fzfselection) = @fzfoutput;

# Gives the ability to run commands by typing :command as a fzf query
#  ! THE SECOND ARG (query or cmd from CMDRET) of @fzfoutput has priority !
if ($query and $query =~ m/^:/) {
    ($cmd, $query) = ($query, "") if (iscmd($query));
}

# Filter command has a special syntax and takes arguments
if ($query and $query =~ m/^filter:/) {
    $cmd   = ":filter";
    $query =~ s/^filter: //;
}

# Context query for commands which need it
$context->{query} = $query if ($query);

# Gets a list of papis folders from the fzf selection
if (@fzfselection) {
    @ordinals = io::fzf_to_ordinals($CACHE, @fzfselection);
    @papisfolders = io::ordinals_to_papis_folders($CACHE, @ordinals);
}

    # Debug output
    if ($DEBUG) {
        print  "\n====\n";
        printf "papis-fzf :: DEBUG fzf cmd : %s\n", @fzfcmd if ($DEBUG == 2);
        printf "papis-fzf :: DEBUG command : %s\n", $cmd;
        printf "papis-fzf :: DEBUG query : %s\n", $query if ($query);
        print  "papis-fzf :: DEBUG query : null\n" if (!$query);
        printf "papis-fzf :: DEBUG papis-folders : %s\n", @papisfolders if (@papisfolders);
        print  "\n";
    }

#=======================
# Reset CMDRET
# Runs the command
#=======================

if ($cmd) {
    $cmd =~ s/^://;                        # gets rid of the : at the beginning
    $cmd =~ s/-//g;                        # it is possible to run papis-fzf search-by-tags
    $context->{from} = "main";             # The cmd will know from where it runs
    my $command      = $cmd . "::" . $cmd;

    $CMDRET = &$command($context, $config, @papisfolders);

    if (@$CMDRET) {
        printf "\npapis-fzf :: DEBUG :%s returns : %s\n\n", $cmd, @$CMDRET if ($DEBUG);
    } else {
        printf "\npapis-fzf :: DEBUG :%s returns : %s\n\n", $cmd, $CMDRET if ($DEBUG);
    }
}

goto MAINLOOP; # Repeats loop !

#====================================================


