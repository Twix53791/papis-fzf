=buildindexes.pm
===============================================
  Builds/updates indexes
  Runs build.py
  @_:
    <context object> <config object> (list of papis-folders)
===============================================
=cut

package buildindexes;
use strict;
no strict "refs";
use warnings;

# The only interactive command:
sub buildindexes {
    my $context = shift;

    if ($context->{from} eq "onerun") {
        print "papis-fzf :: indexing the whoosh papis database...\n";
        add_entries($context, @_);
    } else {
        my $pid = fork;
        die "papis-fzf ERROR :: delete.pm unable to fork: $!."
            unless defined $pid;              # Don't change the syntax here!

         unless ( $pid ) {
            add_entries($context, @_);

            system("pkill fzf-papis");             # refresh fzf menus opened
            exit 0; # !important
        }
    }


    return 0
}

#############################

sub update_indexes {
    remove_entries(@_);
    add_entries(@_);
}


sub remove_deleted_entries {
    remove_entries(@_);
}

sub remove_entries {
    my ($context) = splice @_, 0, 2;

    my $cache = $context->{cachedir};
    my $debug = $context->{debug};
    my $logfile = $context->{logfile};

    my @indexes = ("$cache/index", "$cache/index-raw", "$cache/index-colored");
    my @ordinals = io::papis_folders_to_ordinals($cache, @_);

    # Remove entries from indexes
    foreach my $index (@indexes) {
        my @newcontent;
        open INDEX, "<", $index or die "can't open $index: $!";
            while(<INDEX>){
                push @newcontent, $_ if ( not grep {/^$.$/} @ordinals );
            }
        close INDEX or die "can't close $index: $!";

        open INDEX, ">", $index or die "can't open $index: $!";;
            print INDEX @newcontent;
        close INDEX or die "can't close $index: $!";
    }
}


sub add_entries {
    my ($context, $config) = splice @_, 0, 2;

    my $realbin = $context->{realbin};
    my $logfile = $context->{logfile};

    my $cmd = "python $realbin/core/build.py";
    $cmd   .= " $context->{cachedir} $context->{configdir}";
    $cmd   .= " \"$config->{index_fields}\"";
    $cmd   .= " \"$config->{fzf_fields}\" \"$config->{fzf_colors}\"";
    $cmd   .= sprintf " %s 2>> $logfile", join " ", @_;

    # Debug
    if ($context->{debug}) {
        open my $log, ">>", $logfile;
        print $log "====\npapis-fzf DEBUG :: buildindexes.pm :: add_entries cmd:\n";
        print $log "$cmd\n";
    }
    # Runs the python script building entries
    system $cmd;

}


1;


