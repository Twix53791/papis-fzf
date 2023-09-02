=tag.pm
===============================================
  Add or remove tag(s) of the entries selected
  Dependencies:
    - yq (https://github.com/mikefarah/yq)

  @_:
    <context object> <config object> (list of papis-folders)
===============================================
=cut
package tag;
use strict;
use warnings;

sub tag {
    my ($context, $config) = splice @_, 0, 2;

    # Returns if no argument
    return if (!@_);

    # Gets tags form core::tags, format to echo
    my $taglist = sprintf "\"%s\"", join "\\n", (tags::list($context));

    # Displays tags with fzf
    my @fzfcmd = fzfenv::set_options($context, $config, "tag");
    my $cmd = "echo -en $taglist | @fzfcmd";

    io::fifo_out($context->{fifo_out}, $cmd);
    my @fzfoutput = io::fifo_in($context->{fifo_in});

    chomp foreach @fzfoutput;
    my ($action, $query, @tags) = @fzfoutput;

    # Return if :exit
    return if ($action eq ":exit");

    # Sets tags
    if ($action =~ m/query/) {
        push @tags, split " ", $query;
    }

    # Add or remove tags
    if ($action eq ":remove" or $action eq ":query_rm") {
        tag_remove(\@tags, @_);
    } else {
        tag_add(\@tags, @_);
    }

    # Sends task in the background
    my $pid = fork;
    die "papis-fzf ERROR :: tag.pm unable to fork: $!." unless defined $pid;

     unless ( $pid ) {
        background::update_database(@_);
        buildindexes::update_indexes($context, $config, @_);
        system("pkill fzf-papis");
        exit 0;  # !
    }
}


sub tag_add {
=tag_add
  Add tags to the entries

  @_ : @$tags (list of papis folders)
=cut
    my $tags = shift;     # array ref

    foreach (@_) {
        my $yaml = $_ . "/info.yaml";

        my $entrytags = `yq '.tags' $yaml`;
        my @entrytags = grep {$_ ne "null"} split(" ", $entrytags);


        # Discards tags already in the entry
        my %entrytags = map { $_ => 1 } split " ", $entrytags;
        my @newtags   = grep !$entrytags{$_}, @$tags;

        @newtags = (@entrytags, @newtags);

        if (@newtags) {
            system("yq -i '.tags = \"@newtags\"' $yaml 2>/tmp/toto");
        }
    }

}


sub tag_remove {
    my $tags = shift;

    foreach (@_) {
        my $yaml = $_ . "/info.yaml";

        my $entrytags = `yq '.tags' $yaml`;
        chomp($entrytags);
        next if ($entrytags eq "null");

        # New tags = entrytags not in tags
        my @entrytags = split " ", $entrytags;
        my %tags      = map { $_ => 1 } @$tags;
        my @newtags   = grep !$tags{$_}, @entrytags;

        my $el = @entrytags, my $nl = @newtags;    # Compare lengths

        if (@newtags and $nl < $el) {
            system("yq -i '.tags = \"@newtags\"' $yaml");
        } elsif (!@newtags) {
            system("yq -i '.tags = del(.tags)' $yaml");
        }
    }
}
1;
