=searchbytags.pm
===============================================
  Search the library by tags

  @_:
    <context object> <config object>
  returns : @ordinals (list of linenumbers)
===============================================
=cut
package searchbytags;
use strict;
use warnings;


sub searchbytags {
    my ($context, $config) = @_;
    my $debug = $context->{debug};
    my $logfile = $context->{logfile};
    my @tags;

    # Gets tags form core::tags, format to echo
    my $taglist = sprintf "\"%s\"", join "\\n", (tags::list($context));

    # Displays tags with fzf
    my @fzfcmd = fzfenv::set_options($context, $config, "searchbytags");
    my $cmd = "echo -en $taglist | @fzfcmd";

    RUNFZF:
    io::fifo_out($context->{fifo_out}, $cmd);
    @tags = io::fifo_in($context->{fifo_in});

    chomp foreach @tags;

    # :exit? Exit if from onerun, comes back to main if from main
    if ($tags[0] eq ":exit") {
        exit::exit($context) if ($context->{from} eq "onerun");
        return 0                                # if from main
    }

    # Combine tags with AND or OR operator?
    my $or = ($tags[0] eq ":or") ? 1 : 0;

    # Shift removes command
    shift(@tags) if ($or);

    # Grep the tags in the index file
    my $index = $context->{cachedir} . "/index";
    my @ordinals;  # a list of line numbers matching the search

    # Set regex
    my $regex;

    if ($or) {
        my @regex = map { "\\b" . $_ . "\\b" } @tags;
        $regex = join "|", @regex;
    } else {
        my @regex = map { "(?=.*\\b" . $_ . "\\b)" } @tags;
        $regex = join "", @regex;
    }

    # Debug
    printf "====\npapis-fzf :: DEBUG searchbytags.pm : or regex\n%s\n", $regex if ($debug);

    # Search for matches in index file
    open INDEX, "<", $index or die "can't open $index: $!";
        while (my $line = <INDEX>){
            if ($line =~ m/\|TAGS:/) {          # There is tags on this list
                $line =~ s/.*\|TAGS://;         # remove all before tags field
                ($line) = split /\|/, $line, 2; # remove field(s) after tags field

                if ($line =~ m/($regex)/) {
                    push @ordinals, $.;  # line number if match

                    if ($debug) {
                        printf "papis-fzf :: DEBUG searchbytags.pm : match on line %s\n", $.;
                    }
                }
            }
        }
    close INDEX or die "can't close $index: $!";

    # Turns back to searchbytags menu if no match
    goto RUNFZF if (!@ordinals);

    return \@ordinals
}

1;
