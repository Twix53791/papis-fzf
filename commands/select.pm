=select.pm
===============================================
  Papis-fzf baheves like a file picker.
  Select one or multiples entries, it will print
  the papis-folders to stdout.

  @_:
    <context object> <config object> <@ARGV>
===============================================
=cut
package select;
use strict;
use warnings;


sub select {
    my ($context, $config) = splice @_, 0, 2;
    my $cache              = $context->{cachedir};
    my $fifo_out           = $context->{fifo_out};
    my $fifo_in            = $context->{fifo_in};

    my $fzfindex = "$cache/index-colored";
    my @fzfcmd   = fzfenv::set_options($context, $config, "select");
    my $fzf      = "sort '$fzfindex' | @fzfcmd";

    io::fifo_out($fifo_out, $fzf);
    my @fzfoutput = io::fifo_in($fifo_in);
        # NOTE: the output of select, contrary to the others commands
        # contains only fzf entries, no --print-query, no commands form bindings

    return 0 if ($fzfoutput[0] eq ":exit");

    my @ordinals     = io::fzf_to_ordinals($cache, @fzfoutput);
    my @papisfolders = io::ordinals_to_papis_folders($cache, @ordinals);
    my $toprint      = sprintf ":print\n%s\n", join "\n", @papisfolders;

    # Send to papis-fzf the text to print to sdout
    # As papis-fzf.pl run in background, fifo_out is necessary
    io::fifo_out($fifo_out, $toprint);

    return 0
}

1;
