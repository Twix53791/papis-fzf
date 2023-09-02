=input/output.pm  ========================
  Subroutines used to communicate between:
   - papis-fzf and papis-fzf.pl
   - fzf output, papis commands and
     papis-fzf actions
  I/O though fifos
   - fifo_out
   - fifo_in
  Translate input from :
   - raw fzf output to ordinals
   - ordinals to colored fzf output
   - ordinals to papis folders
   - papis folders to ordinals
===========================================
=cut
package io;
use strict;
use warnings;


sub fifo_out {
=fifo_out
  Sends a command to execute
   to papis-fzf.

  @_ : "fifofile" "command to send"
=cut
    my ($fifo, $cmd) = @_;
    open my $FIFO, ">", $fifo     or die "io.pm :: Can't communicate to papis-fzf via $fifo: $!";
        print $FIFO $cmd;
    close $FIFO                   or die "io.pm :: Can't close fifo $fifo: $!";
}


sub fifo_in {
=fifo_in
  Gets the output of papis-fzf sent
   to papis-fzf.pl.
  In practical, it is a output of fzf.
  It reads a filehandle opened once in
  papis-fzf.pl. * $. will increase forever!

  @_ : <fifo filehandle>
  returns : ("string", ...)
=cut
    my $fifo = shift;
    my @input;

    while (<$fifo>) {
        if (/^--$/) {     # Don't forget this line or it waits forever !
            last;
        }
        chomp;
        push @input, $_;
    }

    return @input
}


sub fzf_to_ordinals {
=fzf_to_ordinals
  Takes the output of fzf, a list of entries (strings)
  Output the ordinal index (line number) of each entry
  in index-raw file as a list of integers.

  @_ : <cachedir> ("string", )
  return : (int, ...)
=cut
    my ($cachedir, @fzfentries) = @_;
    my $indexfile = $cachedir . "/index-raw";

    my @ordinals;

    open my $fh, '<', $indexfile     or die "io.pm :: Can't open $indexfile: $!";

        while (my $line = <$fh>) {
            chomp $line;
            foreach my $entry (@fzfentries ) {
                if ( $line eq $entry ) {
                    # If the line match an fzf entrie,
                    #  add the line number to @ordinals
                    push @ordinals, $.;

                    # Remove the entrie from @fzfentries
                    @fzfentries = grep {$_ ne $entry} @fzfentries;
                }
            }
            last if ( !@fzfentries );
        }

    # The ordinals array is always sorted
    @ordinals = sort { $a <=> $b } @ordinals;

    return @ordinals;
}


sub ordinals_to_fzf {
=ordinals_to_fzf
  Take a list of line numbers, then "grep" those lines
  in index-colored, to constitute an array.
  This array can be piped to fzf directly to display the
  selected library entries.

  @_ : <cachedir> (int, ...)
  return: ("string", ...)
=cut

    my ($cachedir, @ordinals) = @_;
    my $indexfile = $cachedir . "/index-colored";

    my @fzfentries;

    open my $fh, '<', $indexfile     or die "io.pm :: Can't open $indexfile: $!";
    while (<$fh>) {
        chomp;
        if ( $. == $ordinals[0] ) {
            shift @ordinals;         # remove the matched line from @nth
            push @fzfentries, $_;
        }
        last if ( !@ordinals );      # stop while if no more nth line to grep
    }

    @fzfentries = sort @fzfentries;

    return @fzfentries;
}


sub ordinals_to_papis_folders {
=ordinals_to_papis_folders
  Takes the output of fzf_to_ordinals, and then
   retrieves the papis-folders corresponding
   to the entries (line numbers) in the main index file.
  Output an array of papis-folders.

  @_ : <cachedir> (int, ...)
  Return : ("string", ...)
=cut
    my ($cachedir, @ordinals) = @_;
    my $indexfile = $cachedir . "/index";

    my @papisfolders;

    open my $fh, '<', $indexfile     or die "io.pm :: Can't open $indexfile: $!";
    while (my $line = <$fh>) {
        if ( $. == $ordinals[0] ) {
            chomp $line;                 # Gets rid of \n
            shift @ordinals;             # Remove the ordinal matched
            $line =~ s/.*\|//;           # Gets the papis-folders (last field)
            push @papisfolders, $line;
        }
        last if ( !@ordinals );          # stops if no more nth line to grep
    }

    return @papisfolders;
}


sub papis_folders_to_ordinals {
=papis_folders_to_ordinals
  Inverse of ordinals_to_papis_folders
  Takes as input a list of papis folders
  Output an array of ordinals.

  @_ : <cachedir> (string, ...)
  Return : (int, ...)
=cut
    my ($cachedir, @papisfolders) = @_;
    my $indexfile = $cachedir . "/index";

    my @ordinals;

    open my $fh, '<', $indexfile          or die "io.pm :: Can't open $indexfile: $!";
    while (my $line = <$fh>) {
        chomp $line ;                  # Needed to match @papisfolders

        $line =~ s/.*\|//;             # Gets the current line papis folder

        if ( grep {m{^$line$}} @papisfolders ) {
            push @ordinals, $.;

                # Deletes the folder from @papisfolders
            @papisfolders = grep {$_ ne $line} @papisfolders;
        }

        last if ( !@papisfolders );    # stops if no more folders to grep
    }

    @ordinals = sort { $a <=> $b } @ordinals;

    return @ordinals;
}


sub folders_to_papis {
=folders to papis
  Insert "--doc-folder" between the list of papis folders
  Quote folders, in case of spaces into...

  return : (--doc-folder, "folder1", --doc-folder, "folder2", ...)
=cut
    my @doc_folders;
    foreach my $f (@_) {
        push(@doc_folders, "--doc-folder", "\"$f\"")
    }
    return @doc_folders
}


1;
