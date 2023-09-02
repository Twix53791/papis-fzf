=help.pm ========================
  Format help messages displayed
   in the fzf preview.

  @_ : <config object> <mode>
=================================
=cut

sub help {
    my $config = shift,
    my $mode = shift;

    # Colors
    my $T = "\033[" . $config->{help_text};
    my $B = "\033[" . $config->{help_keys_color};

    # Wrap global settings
    $Text::Wrap::columns = `tput cols` - $config->{preview_wrap};
    $Text::Wrap::break = ";";  # breaks on ; character instead of \s

    ##################################
    # Merge global & mode specific keymaps

    my %keymap = eval $config->{global_keys}; # cmd=>key

    # Gets the specific keymaps according to mode
    if ($mode eq "main") {
        %keymap = (%keymap, eval $config->{main_keys}); }
    elsif ($mode eq "cite") {
        %keymap = (%keymap, eval $config->{cite_keys}); }
    elsif ($mode eq "searchbytags") {
        %keymap = (%keymap, eval $config->{searchbytags_keys}); }
    elsif ($mode eq "tag") {
        %keymap = (%keymap, eval $config->{tag_keys}); }
    elsif ($mode eq "add") {
        %keymap = (%keymap, eval $config->{add_keys}); }
    elsif ($mode eq "citations") {
        %keymap = (%keymap, eval $config->{citations_keys});
    }

    ##################################
    # Gets keys
    my @hashkeys = keys %keymap; # cmd
    @hashkeys = sort { $a cmp $b } @hashkeys; # sort keys
    my @keytext;

    # Builds the list of commands/keys, colored
    foreach (@hashkeys) {
        push @keytext, "$B$_ :$T $keymap{$_}"; # "$B key : $T text"
    }

    # Join list in one text
    my $text = join " ; ", @keytext;

    # Prints wrapped text
    print wrap(" ", "", $text) . "\n";

}

1;
