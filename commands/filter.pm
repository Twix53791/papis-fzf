=filter.pm
===============================================
  Execute complex searches in the whoosh database
  Use awk syntax:
  ex: filter: author:"Jean Autard" AND author:Paul
      OR (publisher:Elsevier && tags:toto)

  @_:
    <context object> <config object> (papis-folders)
===============================================
=cut
package filter;
use strict;
use warnings;

sub filter {
    my ($context, $config) = splice @_, 0, 2;
    my $index              = $context->{cachedir} . "/index";
    my $query              = $context->{query};

  ## Determines the field order
    my $fields = $config->{index_fields};
    $fields    =~ tr/[]/()/;                # ref list format to array
    my @fields = eval $fields;

    my %nthfield; my $i=1;
    foreach (@fields) { $nthfield{$_} = "$i"; $i++; }

  ## Query -> awk format
    foreach (keys %nthfield) {
        $query =~ s/$_/\$$nthfield{$_}/g; } # field name -> column number

    # Double quotes all patterns:
    $query =~ s/:([^\"].*?)( |\)|$)/:\"$1\"$2/g;
    # : [not "] (.*?) (" " or ")" or endline)
    #            $1              $2

    $query = $query =~ tr/:/~/r
                    =~ s/AND/&&/rg
                    =~ s/OR/\|\|/rg;

    printf "====\npapis-fzf DEBUG :: filter.pm regex query: %s\n", $query
           if ($context->{debug} == 2);

    my @ordinals = `awk -v FS=\"|\" -v IGNORECASE=1 '$query {print NR}' $index`;

    return (@ordinals) ? \@ordinals : 0;
}

1;
