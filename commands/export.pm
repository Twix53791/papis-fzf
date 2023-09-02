=export.pm
===============================================
  Exports the entries to bibtex/json/yaml file.
  Uses `papis export`

  @_:
    <context object> <config object> (papis-folders)
===============================================
=cut
package export;
use strict;
use warnings;

sub export {
    my ($context, $config) = splice @_, 0, 2;
    my $logfile = $context->{logfile};

    # Run fzf and capture output
    my @fzfcmd = "fzf-papis " .
                 "--reverse +m --no-clear " .
                 "--bind 'change:first,esc:execute(echo :exit)+abort'";
    my $cmd    = "echo -e 'bibtex\\njson\\nyaml\\n' | @fzfcmd";

    io::fifo_out($context->{fifo_out}, $cmd);
    my $exformat = (io::fifo_in($context->{fifo_in}))[0];
        return 0 if ($exformat eq ":exit");

    my $ext     = "." . $exformat;
    $ext        =~ s/bibtex/bib/;

    # Run script, capture output
    my $script = sprintf "%s/scripts/filepicker.sh", $context->{configdir};
        return 0 if (not -f $script);
        $script   .= " 2>/dev/null";

    io::fifo_out($context->{fifo_out}, $script);
    my $outfile = (io::fifo_in($context->{fifo_in}))[0];
        return 0 if (not $outfile);

        if (-d $outfile) {
            my $error = "ERROR :: export path must be a file.";
            background::notify($context, $config, $error, "error");
            return 0
        }

    $outfile =~ s/\.[^.]+$//;
    $outfile .= $ext;

    # Sends task in the background
    my $pid = fork;
    die "papis-fzf ERROR :: export.pm unable to fork: $!."
        unless defined $pid;              # Don't change the syntax here!

     unless ( $pid ) {
        my @docfolders = io::folders_to_papis(@_);
        my $msg        = "Entries added to $outfile";

        system("papis export -a -f $exformat -o '$outfile' @docfolders 2>> $logfile");
        background::notify($context, $config, $msg);

        exit 0; # !important
    }

    return 0
}

1;
