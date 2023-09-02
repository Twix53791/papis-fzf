=show.pm
===============================================
  Show yaml view.
  Show the content of info.yaml file(s).
  Show only the fields selected in the config.

  Dependencies: yq (https://github.com/mikefarah/yq)
  @_:
    <context object> <config object> (list of papis-folders)
===============================================
=cut
package show;
use strict;
no  strict "refs";
use warnings;
use Text::Wrap;

sub show {
    my ($context, $config) = splice @_, 0, 2;

    return 0 if (!@_);     # Returns if no argument

    my $debug              = $context->{debug};
    my @fields             = eval $config->{show_fields};
    my %colors             = eval $config->{show_colors};
    my @wrap               = ("  ", "   ", 3); # default wrap values
    my @confwrap           = (eval $config->{show_wrap});

    # Update @wrap with config values
    foreach (0..$#confwrap) {
        $wrap[$_] = $confwrap[$_];
    };

    # Wrap text length
    $Text::Wrap::columns = `tput cols` - $wrap[2];

    print_output($config, \@wrap, @_);

    # If run:
    #   - from main, waits for user input
    #   - from another command, just skip this step,
    #          the command will handles the prompt...
    my $from = $context->{from};
    my $cmd;
    my @ordinals;

    if ($from eq "main") {
        $cmd = ":" . read_key($context, $config);

        if ($cmd) {
            @ordinals = io::papis_folders_to_ordinals($context->{cachedir}, @_);
            unshift @ordinals, $cmd;

            print "papis-fzf :: DEBUG show view command: $cmd\n"         if ($debug);
            print "papis-fzf :: DEBUG show view command arguments: @_\n" if ($debug);
        }

        system("tput reset") if (!$debug);        # Clears terminal
    }

    return (@ordinals) ? \@ordinals : 0;
}


sub print_output {
# @_ : <config> @$wrap (list of papis folders)
    my ($config, $wrap) = splice @_, 0, 2;
    my @fields          = eval $config->{show_fields};
    my %colors          = eval $config->{show_colors};
    my @wrap            = @$wrap;

    foreach (@_) {
        # Parses it with yq
        my $yamlfile = "$_/info.yaml";
        my @yq       = `yq 'to_entries | from_entries' $yamlfile`;
        my %yaml;

        # Builds a hash of pairs key/value
        foreach (@yq) {
            chomp;
            my ($key, $value) = split ": ", $_, 2;
            $yaml{$key}       = $value;
        }

        # Print a separator if the loop indice > 0
        if ($_ ne $_[0]) {
            my $tw = `tput cols`;   # get terminal width
            print "\n" . "=" x $tw; # print line separator
        }

        # Prints the colored pairs in the terminal
        #  if there are found in @fields (config setting)
        foreach (@fields) {
            if (exists $yaml{$_}) {
                my $color = $colors{value}; # Default value color
                $color = $colors{$_} if (exists $colors{$_}); # custom color
                print wrap($wrap[0], $wrap[1],
                      "\033[$colors{key}" .     # key color
                      "$_:" .         # key
                      " \033[$color" .    # value color
                      "$yaml{$_}\033[0m\n"); # value
            }

            # Print a newline separator below the fields:
            #  title, author, abstract
            if ($_ eq "title" or $_ eq "author" or $_ eq "abstract") {
                print "\n";
            }
        }
    }
}


sub read_key {
# @_ : <context> <config>
        my ($context, $config) = @_;
        my $debug = $context->{debug};

        # Gets the keybindings from the config
        my %keymap = eval $config->{show_keys}; # cmd=>key
        my %mapkey = reverse %keymap; # key=>cmd
        my %keyaliases = eval $config->{show_keys_aliases};

        my @hashkeys = keys %keymap; # cmd
        @hashkeys = sort { $a cmp $b } @hashkeys;
        my @keytext;

        # Builds the list of commands/keys
        foreach (@hashkeys) {
            my $value = $keymap{$_};
            $value = $keyaliases{$_} if (exists $keyaliases{$_});

            push @keytext, "$_ ($value)"; # "cmd (key or key alias)"
        }

        my $text = join " ; ", @keytext;

        # Prints the text displaying the key bindings
        print "\n\033[$config->{show_keys_color}" . # color
              "  actions: $text \033[0m\n\n";

        # Wait & read user input
        io::fifo_out($context->{fifo_out}, ":read");
        my $key = (io::fifo_in($context->{fifo_in}))[0];

        my $cmd;

        # 'Case' statement
        for ($key) {
            my $ord = ord $key; # Get the numeric value of the key
                                # To bind specials keys like ENTER

            (exists $mapkey{$key}) and do { $cmd = $mapkey{$key}; last;};
            (exists $mapkey{$ord}) and do { $cmd = $mapkey{$ord}; last;};
            $cmd = 0;
        }

        return $cmd
}

1;
