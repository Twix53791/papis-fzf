package fzfenv;
use strict;
no strict "refs";
use warnings;

sub set_options {
    # config : gets the keybindngs set in the config
    # mode   : in which menu are we?
    my ($context, $config, $mode) = splice @_, 0, 3;

    my $previewscript = $context->{preview};
    my $realbin       = $context->{realbin};
    my $configdir     = $context->{configdir};
    my $cachedir      = $context->{cachedir};
    my $helpfile      = $context->{tmpdir}  .  "/preview-help";
    my $logfile       = $context->{logfile};
    my $debug         = $context->{debug};

    # Sets help mode to 0
    open my $h, ">", $helpfile;
        print $h 0;

#    my   @fzfoptions = qw(fzf-papis --reverse -m --ansi);
#    push @fzfoptions, "--print-query" if ($mode ne "searchbytags");

#    my $noclear = "--no-clear" if (!$debug and $config->{no_clear});
#    push @fzfoptions, $noclear if ($noclear);

    my @previewopts = ($previewscript, $realbin, $configdir, $cachedir, $logfile, $helpfile);

    my @fzfoptions = &$mode($context, $config, $helpfile, @previewopts);

#    push @fzfoptions, "--bind", $bindings;
#    push @fzfoptions, @preview if (@preview);

    print "====\npapis-fzf :: DEBUG fzfenv.pm fzfoptions : @fzfoptions\n\n" if ($debug == 2);

    return @fzfoptions
}


=Subroutines specific to menus ========
  Sets keybindings for each mode

  @_ : <context object> <config object> @previewopts
  returns : a string
=======================================
=cut

sub main {
# main menu (papis-fzf.pl)
    my ($context, $config, $helpfile) = splice @_, 0, 3;

    my @fzfoptions = qw(fzf-papis --reverse -m --ansi --print-query --bind);

    my %key        = (eval $config->{global_keys}, eval $config->{main_keys});

    my $bindings   =
        "'change:first,"      .
        "$key{cite}:"         .  "execute(echo :cite)+accept," .
        "$key{searchbytags}:" .  "execute(echo :searchbytags)+accept," .
        "$key{show}:"         .  "execute(echo :show)+accept," .
        "$key{edit}:"         .  "execute(echo :edit)+accept," .
        "$key{delete}:"       .  "execute(echo :delete)+accept," .
        "$key{tag}:"          .  "execute(echo :tag)+accept," .
        "$key{citations}:"    .  "execute(echo :citations)+accept," .
        "$key{browse}:"       .  "execute(echo :browse)+accept," .
        "$key{export}:"       .  "execute(echo :export)+accept," .

#        "$key{buildindexes}:" .  "execute(echo :buildindexes)+abort," .
#        "$key{yank}:"        .    "execute-silent($yankscript {})," .
        "$key{selectall}:"    .  "select-all," .
        "$key{deselectall}:"  .  "deselect-all," .
        "$key{help}:"         .  "execute-silent(echo 1 > $helpfile)+refresh-preview," .
        "esc:"                .  "execute(echo :exit)+abort'";

    push @fzfoptions, $bindings;

    my @previewopts = @_;
        push @previewopts, "main";

    my @preview = ("--preview", "'perl @previewopts {}'",
                   "--preview-window", "bottom,30%,wrap");

    push @fzfoptions, @preview;

    return @fzfoptions
}

sub searchbytags {
# from searchbytags.pm
    my ($context, $config, $helpfile) = splice @_, 0, 3;

    my @fzfoptions = qw(fzf-papis --reverse -m --bind);

    my %key      = (eval $config->{global_keys}, eval $config->{searchbytags_keys});

    my $bindings =
        "'change:first,"     .
        "$key{accept}:"      . "accept," .
        "$key{or}:"          . "execute(echo ':or')+accept," .
        "$key{selectall}:"   . "select-all," .
        "$key{deselectall}:" . "deselect-all," .
        "$key{help}:"        . "execute-silent(echo 1 > $helpfile)+refresh-preview," .
        "esc:"               . "execute(echo ':exit')+abort'";

    push @fzfoptions, $bindings;

    my @previewopts = @_;
        push @previewopts, "searchbytags";

    my @preview = ("--preview", "'perl @previewopts {}'",
                   "--preview-window", "bottom,8%,wrap,border-none");

    push @fzfoptions, @preview;

    return @fzfoptions
}

sub tag {
# from tag.pm
    my ($context, $config, $helpfile) = splice @_, 0, 3;

    my @fzfoptions = qw(fzf-papis --reverse -m --print-query --bind);

    my %key      = (eval $config->{global_keys}, eval $config->{tag_keys});

    my $bindings =
        "'change:first,"      .
        "$key{accept}:"      . "execute(echo :accept)+accept," .
        "$key{remove}:"      . "execute(echo :remove)+accept," .
        "$key{query_add}:"   . "execute(echo :query_add)+accept," .

        "$key{selectall}:"   . "select-all," .
        "$key{deselectall}:" . "deselect-all," .
        "$key{help}:"        . "execute-silent(echo 1 > $helpfile)+refresh-preview," .
        "esc:"               . "execute(echo :exit)+abort'";

    push @fzfoptions, $bindings;

    my @previewopts = @_;
        push @previewopts, "tag";

    my @preview = ("--preview", "'perl @previewopts {}'",
                   "--preview-window", "bottom,8%,wrap,border-none");

    push @fzfoptions, @preview;

    return @fzfoptions
}

sub add {
# from add.pm
    my ($context, $config, $helpfile) = splice @_, 0, 3;

    my @fzfoptions = qw(fzf-papis --reverse -m --print-query --bind);

    my %key      = (eval $config->{global_keys}, eval $config->{add_fzf_keys});

    my $bindings =
        "'change:first,"      .
        "$key{query}:"       .  "execute(echo ':query')+accept," .

        "$key{selectall}:"   .  "select-all," .
        "$key{deselectall}:" .  "deselect-all," .
        "$key{help}:"        .  "execute-silent(echo 1 > $helpfile)+refresh-preview," .
        "esc:"               .  "abort'";

    push @fzfoptions, $bindings;

    my @previewopts = @_;
        push @previewopts, "add";

    my @preview = ("--preview", "'perl @previewopts {}'",
                   "--preview-window", "bottom,8%,wrap,border-none");

    push @fzfoptions, @preview;

    return @fzfoptions
}


sub cite {
# from cite.pm
    my ($context, $config, $helpfile) = splice @_, 0, 3;

    my @fzfoptions = qw(fzf-papis --reverse +m --ansi --no-clear --bind);

    my %key        = (eval $config->{global_keys}, eval $config->{cite_fzf_keys});

    my $bindings   =
        "'change:first,"      .
        "$key{edit}:"       .  "execute(echo :edit)+abort," .

        "$key{help}:"        .  "execute-silent(echo 1 > $helpfile)+refresh-preview," .
        "esc:"               . "execute(echo :exit)+abort'";

    push @fzfoptions, $bindings;

    my @previewopts = @_;
        push @previewopts, "cite";

    my @preview = ("--preview", "'perl @previewopts {}'",
                   "--preview-window", "bottom,7%,wrap,border-none");

    push @fzfoptions, @preview;

    return @fzfoptions
}

sub select {
# from select.pm
    my ($context, $config, $helpfile) = splice @_, 0, 3;

    my @fzfoptions = qw(fzf-papis --reverse +m --ansi --bind);

    my %key        = (eval $config->{global_keys}, eval $config->{cite_fzf_keys});

    my $bindings   =
        "'change:first," . "esc:execute(echo :exit)+abort'";

    push @fzfoptions, $bindings;

    return @fzfoptions
}


1;
