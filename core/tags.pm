=tags.pm  =========================
  Lists unique tags found in index
===================================
=cut
package tags;
use strict;
use warnings;

# @_ : <context object>
# returns : ("string", ...)
sub list {
    my $context = shift;
    my $index = $context->{cachedir} . "/index";
    my $debug = $context->{debug};

    # Parses index file & list tags
    my (@tags, %tags);

    open INDEX, "<", $index or die "can't open $index: $!";
        while (my $line = <INDEX>){
            if ($line =~ m/\|TAGS:/) {          # There is tags on this list
                $line =~ s/.*\|TAGS://;         # remove all before tags field
                ($line) = split /\|/, $line, 2; # remove field(s) after tags field
                push my @newtags, split " ", $line; # split tags

                # Foreach new tag, if it is not already
                #  a hash key, add it to %tags
                foreach (@newtags) {
                    $tags{$_} = 1 if (! $tags{$_});
                }
            }
        }
    close INDEX or die "can't close $index: $!";

    # Builds a sorted list of tags
    push @tags, sort { $a cmp $b } keys %tags;

    # Debug output
    if ($debug == 2) {
        print "papis-fzf :: DEBUG list tags :\n";
        printf "%s\n", join "", @tags;
    }

    return @tags
}

1;
