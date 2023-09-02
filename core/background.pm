=background.pm ====================
  Runs from papis-fzf/core/pipe.sh
   (run directly by papis-fzf).
  Executes tasks in the background.
===================================
=cut
package background;
use strict;
#no strict 'refs';
use warnings;


# Runs `papis update -b --doc-folder folder1 --doc-folder ...`
sub update_database {
    my @docfolders = io::folders_to_papis(@_);
    system("papis update -b @docfolders 2>/dev/null");
}

# Gets titles of the entries from papis-folder/info.yaml
# return : full title, without \n and without yaml kay value
sub get_titles {
    my @titles;
    foreach my $folder (@_) {
        my $yaml = $folder . "/info.yaml";

        open Y, "<", $yaml;
        while(<Y>) {
            if (/^title: /) {
                chomp; # removes \n
                $_ =~ s/^.{7}//; # removes first 7 charac
                push @titles, $_;
            }
        }
        close Y;
    }
    return @titles
}


# Runs the notify script to notify the entries updated/deleted
# @_ : <context object> <config object> ("string", ...)
sub notify {
    my ($context, $config) = splice @_, 0, 2;
    my $configdir          = $context->{configdir};
    my $logfile            = $context->{logfile};

    # Parses the config file to check if notifications are enabled
    my $enabled = $config->{enable_notifications};
    $enabled    = 1 if ($_[1] eq "error");                # Always notify if error

    my @quoted  = map { "\"" . $_ . "\"" } @_;            # To send properly args to the shell script

    # Runs the notify script, redirects 2> to $logfile
    my $script = sprintf "%s/scripts/notify.sh", $context->{configdir};
       return 0 if (not -f $script);
       $script   .= " 2>/dev/null";

    system("$script @quoted 2>> $logfile") if ($enabled);
}

1;

