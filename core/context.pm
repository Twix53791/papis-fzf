=context.pm  =================
  Context object
  This object store "global"
   variables values share
   among all the commands.
  This object is passed to all commands.
  To get a value in a command:
   my $context = shift; # <context> is passed as first argument
   my $value = $context->{key}
  To set a new value:
   $context->{key} = $value
==============================
=cut
package context;
use strict;
use warnings;

# Default values (run at init from main.pl)
sub command_context {
   my $class = shift;
   my $self = {
      realbin      => shift,
      fifo_out     => shift,
      fifo_in      => shift,
      configdir    => shift,
      cachedir     => shift,
      tmpdir       => shift,
      logfile      => shift,
      debug        => shift,
      preview      => shift,
   };
   bless $self, $class;
   return $self;
}
1;

=Suplementary keys added later
  Context object will be added of the following keys,
   after this initialization :
    fifo => $FIFO    (papis-fzf bin file)
    query => $query  (papis-fzf bin file)
    from => <module name>  # to know from where a cmd is run
=cut
