=exit.pm
===============================================
  Exits the program.
  Sends an exit message to papis-fzf, letting
   the bash script handling safely the exit.
===============================================
=cut
package exit;

sub exit {
    my $context = shift;
    my $cmd = "\n:--exit--\n";
    io::fifo_out($context->{fifo_out}, $cmd);
}

1;
