=edit.pm
===============================================
  Edits the info.yaml file
  Uses an editor
  @_:
    <context object> <config object> (list of papis-folders)
===============================================
=cut
package edit;
use strict;
use warnings;

sub edit {
    my ($context, $config) = splice @_, 0, 2;

    my $editor = $config->{editor} || $ENV{EDITOR};
    return 0 if (!$editor);

    return 0 if (!@_);     # Returns if no argument

    # From papis-folders to info.yaml paths
    my @toedit = map { "'". $_ . "/info.yaml" . "'" } @_;

    # Runs editor
    my $cmd = sprintf ":edit $editor %s", join " ", @toedit;    # don't forget :edit !
    io::fifo_out($context->{fifo_out}, $cmd);
    io::fifo_in($context->{fifo_in});                           # Needed to wait for the previous process

    # Sends task in the background
    my $pid = fork;
    die "papis-fzf ERROR :: edit.pm unable to fork: $!."
        unless defined $pid;              # Don't change the syntax here!

     unless ( $pid ) {
        #in child. Needs $SIG{CHLD}='IGNORE'; in parent to work
        background::update_database(@_);
        buildindexes::update_indexes($context, $config, @_);
        system("pkill fzf-papis");             # refresh fzf menus opened
        exit 0; # !important
    }

    return 0
}

1;
