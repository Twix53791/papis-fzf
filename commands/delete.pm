=delete.pm
===============================================
  Deletes the entries
  Uses papis rm
  @_:
    <context object> <config object> [list of papis-folders]
===============================================
=cut
package delete;
use strict;
use warnings;


sub delete {
    # Runs the display script
    my ($context, $config) = splice @_, 0, 2;
    my $debug              = $context->{debug};

    return 0 if (!@_);     # Returns if no argument

    # Runs the show view
    $context->{from}   = "delete";
    show::show($context, $config, @_);

    # Asks confirmation

    my $tw = `tput cols`;                         # gets terminal width

    print "\n" . "\033[31m" . "=" x $tw;          # prints line separator
    print "  Do you really want to delete the currently listed entries ?\n" .
          "  yY/nN ?\n\n\033[0m";

    # Wait & read user input
    io::fifo_out($context->{fifo_out}, ":read");
    my $key = (io::fifo_in($context->{fifo_in}))[0];

    if ( $key eq "Y" or $key eq "y" ) {

        # Sends task in the background
        my $pid = fork;
        die "papis-fzf ERROR :: delete.pm unable to fork: $!."
            unless defined $pid;              # Don't change the syntax here!

         unless ( $pid ) {
            #in child.
            my $logfile    = $context->{logfile};
            my @docfolders = io::folders_to_papis(@_);
            my @titles     = background::get_titles(@_);
            my $msg        = "The following entries has been deleted :";

            system("papis rm -f -a @docfolders 2>> $logfile");

            buildindexes::remove_deleted_entries($context, $config, @_);
            background::notify($context, $config, $msg, @titles);

            system("pkill fzf-papis");             # refresh fzf menus opened
            exit 0; # !important
        }

    } else {
        # Operation cancelled if any other key than y/Y is pressed
        print "\033[94m" . "  Operation cancelled. Exit.\n\n";
        system("sleep 0.3");
    }

    system("tput reset") if (!$debug);

    return 0
}

1;
