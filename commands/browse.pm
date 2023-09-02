=browse.pm
===============================================
  Browses the given entries
  Uses papis browse
  @_:
    <context object> <config object> (list of papis-folders)
===============================================
=cut
package browse;
use strict;
use warnings;

sub browse {
    my ($context) = splice @_, 0, 2;
    my $logfile = $context->{logfile};

    return 0 if (!@_);                  # Returns if no argument

    # Check if the entries are "browsable" (have a doi/url)

    # Sends task in the background
    my $pid = fork;
    die "papis-fzf ERROR :: browse.pm unable to fork: $!." unless defined $pid; # Don't change the syntax here!

     unless ( $pid ) {
        #in child. Needs $SIG{CHLD}='IGNORE'; in parent to work
        my @docfolders = io::folders_to_papis(@_);
        system("papis browse -a @docfolders 2>> $logfile");

        exit 0;
    }

    # Exit papis-fzf (exit.pm)
    exit::exit($context);
}

1;
