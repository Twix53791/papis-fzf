=readkey.pm  =========
  Small tools to get
  the ordinal codes of
  your keyboard keys

======================
=cut
package readkey;
use strict;
use warnings;


sub readkey {
    my $context = shift;

    print "press a key. Ctrl-c to exit\n";
    while (1) {
            io::fifo_out($context->{fifo_out}, ":read");
            my @key  = io::fifo_in($context->{fifo_in});

            my $char = "char $key[0]";

            my $ord  = ord $key[0];
            printf "%s  |  %s %s\n", $char, $ord;
    }
}

1;
