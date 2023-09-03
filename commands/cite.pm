=cite.pm
===============================================
  Cite the entries
  Use a clipboard manager

  @_:
    <context object> <config object> (list of papis-folders)
===============================================
=cut
package cite;
use strict;
use warnings;


sub cite {
    my ($context, $config) = splice @_, 0, 2;
    my $citefile           = $context->{configdir} . "/cite_styles";
    my $tmpfile            = $context->{tmpdir} . "/cite_styles_tmp";
    if (not -f $citefile) {
        my $error = "ERROR :: cite_styles file not found.";
        background::notify($context, $config, $error, "error");
        return 0
    }

    cite_parse_styles($config, $citefile, $tmpfile);

    # Fzf menu displaying the styles
    RUNFZF:
    my @fzfcmd = fzfenv::set_options($context, $config, "cite");
    my $cmd    = "cat $tmpfile | @fzfcmd";

    io::fifo_out($context->{fifo_out}, $cmd);
    my $style = (io::fifo_in($context->{fifo_in}))[0];
        return 0 if ($style eq ":exit");
#    system("notify-send \"$style\"");

    # Edit the cite_styles file if :edit
    if ($style eq ":edit") {
        cite_edit($context, $config, $citefile);
        goto RUNFZF
    }

    # 
    my $sep  = $config->{cite_separator};
    my $mode = ($style =~ /^\*/) ? "rich" : "raw";
    $style   =~ s/^.*?$sep//;
    my @citations;

    open my $tmp, ">", $tmpfile;
    foreach (@_) {
        my $yaml     = $_ . "/info.yaml";
        my $citation = $style;

        for my $field ($style =~ /{([^}]*)}/g) {
            my $value = `yq '.$field' $yaml`;
            chomp($value);
            $citation =~ s/{$field}/$value/g;
        }
        print $tmp $citation;
    }
    close $tmp;

    # Sends task in the background
    my $pid = fork;
    die "papis-fzf ERROR :: browse.pm unable to fork: $!." unless defined $pid; # Don't change the syntax here!

     unless ( $pid ) {
        #in child. Needs $SIG{CHLD}='IGNORE'; in parent to work
        # Runs the cite script
        my $script = sprintf "%s/scripts/cite.sh", $context->{configdir};
           return 0 if (not -f $script);
           $script   .= " 2>/dev/null";
        system("$script $mode $tmpfile");

        exit 0;
    }

    exit::exit($context);
}


sub cite_parse_styles {
    my ($config, $citefile, $tmpfile) = @_;

    # Parse cite_file format
    open my $styles, '<', $citefile  or return 0;
    open my $tmp, ">", $tmpfile
            or die "papis-fzf ERROR :: Can't write $tmpfile: $!";

    my $DC = $config->{cite_default_color};
       $DC = "0m" if (not $DC);
    my $NC = $config->{cite_stylename_color};
    my $SC = $config->{cite_script_color};
    my %FC = eval $config->{cite_field_colors};

    while (<$styles>) {
        if (not /^#/ and not /^$/ and not /^\s+$/) {
            s/\[/\033\[$SC\[/g if ($SC);    # [script] color
            s/\]/\]\033\[$DC/g if ($SC);
            s/\|/\|\033\[$DC/g;             # citation color

            foreach my $field (keys %FC) {
                s/($field)/\033\[$FC{$field}$1\033\[$DC/xg;
            }

            if ($NC) { printf $tmp "\033[%s$_", $NC; }
            else     { print  $tmp "$_\033[0m"; }
        }
    }
    close $tmp, $styles;
}

sub cite_edit {
    my ($context, $config, $citefile) = @_;

    my $editor = $config->{editor} || $ENV{EDITOR};
        return 0 if (!$editor);
    my @opts   = eval $config->{edit_default_opts};

    my $cmd = sprintf ":edit %s %s", join " ",
                        $editor, @opts, $citefile;    # don't forget :edit !
    io::fifo_out($context->{fifo_out}, $cmd);
    io::fifo_in($context->{fifo_in});
}

1;
