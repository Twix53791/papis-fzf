=preview.pm
  Fzf preview script

  It is not integrated to papis-fzf.
  It runs by itself from `perl /path/to/preview.pm`,
   run by fzf directly.
  The mode correspond to the fzf environment:
      main   (main fzf menu)
      cite   (cite menu)
      citations  (citations menu)

  @ARGV : <realbin> <configdir> <logfile> <mode> {fzf entry}
=cut
use strict;
use warnings;
use Text::Wrap;
use lib "$ARGV[0]";
use core::config;
use core::io;

# Parses arguments
my ($realbin, $configdir, $cachedir, $logfile, $tmpfile, $mode) = @ARGV;
my $help;

open H, "+<", $tmpfile;
    $help = <H>;   # help is set to 1 or undef
    seek H, 0, 0;  # goto 0,0 position in file
    truncate H, 0; # erase the line
close H;

# Redirects errors to logfile
open my $LOG, ">>", $logfile or die "preview.pm Can't open $logfile: $!";
*STDERR = $LOG;

END {
    close $LOG;
}

# Parses the config
my $config = parse_config config($configdir);

# If <help> mode, runs help.pm
if ($help) {
    my $helpfile = $configdir . "/modules/help.pm";
    $helpfile = $realbin . "/modules/help.pm" if (not -f $helpfile);
    require $helpfile;
    help($config, $mode);
    exit;
}

exit if (!@ARGV);


=preview =========================================
  preview.pm receive as argument the fzf raw text
   of the selected entry.
  It uses io::fzf_to_ordinals to translate it to ordinals
  then io::ordinals_to_fzf to get the colored text
==================================================
=cut

$Text::Wrap::columns = `tput cols` - $config->{preview_wrap};

if ($mode eq "main") {
    my @ordinals = io::fzf_to_ordinals($cachedir, @ARGV);
    my @coloredtext = io::ordinals_to_fzf($cachedir, @ordinals);

    # Format preview. This uses the fact than the fields are
    #  delimited by colors (ansi codes), so it is possible to
    #  format the text according to fields by this trick.
    my %aliases = eval $config->{preview_aliases};
    my @keys = keys %aliases;
    my $formatedtext = $coloredtext[0];

    foreach (@keys) {
        my $m = $_;           # string to match
        my $r = $aliases{$_}; # replacement string

        # If \n found in replacement string, format it this way
        if ($r =~ m/.*\\n/) {
            $r = substr($r, 0, index($r, "\\"));
            $formatedtext =~ s/$m/$r\n/;
        } else {
            $formatedtext =~ s/$m/$r/;
        }
    }

    print wrap(" ", " ", $formatedtext) . "\n";
}

