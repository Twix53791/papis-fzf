=add.pm
===============================================
  Adds an url/doi to papis library
  Uses papis add
  @_:
    <context object> <config object> (list of papis-folders)
===============================================
=cut
package add;
use strict;
use warnings;
use Text::Wrap;
use IPC::Run3;

sub add {

    my ($context, $config, $url) = @_; # parses args
    my $logfile = $context->{logfile}; # for run3
    my @tags;                          # tags

    $context->{debug} = 1;

    # If doi
    $url = "--from doi $url" if ($url =~ m/doi.org/);

    # Mode auto
    my $auto = ($config->{tags_auto}) ? 1 : 0;
    my $lasttags = $context->{cachedir} . "/add-last-tags";

    if ($auto and -f $lasttags) {
        open FH, "<", $lasttags or die "can't open $lasttags: $!";
            push @tags, split(/ /, <FH>);
        close FH or die "can't close $lasttags: $!";
        # Debug
        print "papis-fzf :: DEBUG add.pm auto tags: @tags\n" if ($context->{debug});
    }


    # Parses keymap
    my ($keyaction, $keylabel) = parse_keymap($config);

    # Runs tag menu (fzf) ; overwrites auto tags if output
    TAGMENU:
    my @fzfoutput = tag_menu($context, $config, $logfile);
    @tags = @fzfoutput if (@fzfoutput);

    # Runs confirm menu
    CONFIRM:
    my ($key, $ord) = confirm_menu($context, $config, $keylabel, $url, @tags);

    # Gets the action from the key pressed in confirm menu
    my $action = action($context, $config, $key, $ord, $keyaction);

    # In case of $action:

    for ($action) {
#        ($action eq "create") and do {
#                     create_from_yaml($config, $logfile, $url, @tags); last; };
        ($action eq "back") and do { goto TAGMENU; last;};
        ($action eq "clear") and do { @tags = (); goto CONFIRM; last;};
        ($action eq "exit") and do { exit::exit($context); };
         papis_add($action, $context, $config, $logfile, $url, @tags);
    }
}


=Tags menu (to choose tags) ==============
  In this fzf menu you can:
      - pick-up tags
      - create tags

  @_ : <context> <config> "logfile"
  returns : (tags)
==========================================
=cut
sub tag_menu {
    my ($context, $config, $logfile) = @_;
    my @tags;

    # Gets tags form core::tags
    my @taglist = (tags::list($context));

    # Displays tags with fzf
    my @fzfcmd = fzfenv::set_options($context, $config, "add");

    run3 \@fzfcmd, \@taglist, \@tags, \$logfile;

    # Adds query (create tags) or not?
    my $query = ($tags[0] eq ":query") ? 1 : 0;

    # Shift removes the query OR the cmd ":query"
        # So if !$query, we remove the query,
        #    if $query, we keep it (:query is the 1st line removed)
    shift(@tags);

    # Flattens the array
    @tags = split " ", join " ", @tags;

    return @tags
}


=Parse add_keys  =========================
  The config options setting keybindings
   are formatted in the following way:

   key:keyname => action:label

  It constitutes a hash ; key can be a string
   or and integer (usefull to get specials
   keys like enter, esc, backspace)
  the keyname and label are optional.

  Parse_keymap takes that hash & returns
  two hashes:
    - key => action      (action in action)
    - keynames => label  (text in confirm menu)
  @_ : <config> "mode"
  returns : a list
==========================================
=cut
sub parse_keymap {
    my $config = shift;
    my %keymap = eval $config->{add_keys};
    my ($keyaction, $keylabel) = ({}, {});

    foreach (keys %keymap) {
        my ($key, $keyname) = split /:/, $_;
        my ($action, $label) = split /:/, $keymap{$_};

        # Appends the hash reference with key/action pairs
        $keyaction->{$key} = $action;

        # Appends keylabel with keyname/label pairs
        $keyname = $key if (!$keyname);
        $label = $action if (!$label);

        $keylabel->{$keyname} = $label;
    }

    return $keyaction, $keylabel
}


=Confirm menu  ===========================
  @_ : <context> <config> "url" (tags)
  returns : key pressed
==========================================
=cut
sub confirm_menu {
    my ($context, $config, $hashref, $url, @tags) = @_;

    # Colors: header, binding: labels, binding: key, url, tags
        my @colors = eval $config->{add_menu_colors};
        my ($L, $K) = ("\033[$colors[1]", "\033[$colors[2]");

    # Wrap setting
        my @wrap = ("  ", "  ", 3); # default wrap values
        my @confwrap = (eval $config->{add_wrap});

        # Update @wrap with config values
        foreach (0..$#confwrap) {
            $wrap[$_] = $confwrap[$_];
        };

        # Wrap text length
        $Text::Wrap::columns = `tput cols` - $wrap[2];


    # Sorts keynames
    #  %keylabel : keyname => label
    my %keylabel = %$hashref;
    my @sortedkeys = keys %keylabel;
       @sortedkeys = sort { $a cmp $b } @sortedkeys;

    # Builds a list of commands/keys, colored
    # "$L text ($K key)"
    my @labels;
    push @labels, "$L$keylabel{$_} ($K$_$L)" foreach (@sortedkeys);

    # Text of the menu
    my $menutext;
    $menutext .= "\033[" . $colors[0] . "add the reference to your papis library ?\n";

    # Joins list in one text, appends $menutext
    $menutext .= sprintf "%s\n", join(" ; ", @labels);

    # Appends to text url and tags
    $menutext .= sprintf "\033[%surl: %s\n", $colors[3], $url;
    $menutext .= sprintf "\033[%stags: %s\033[0m\n", $colors[4], join(" ", @tags);

        # Debug
        if ($context->{debug}) {
            print  "papis-fzf :: DEBUG add.pm confirm_menu: ";
            printf "%s, %s, %s\n", $context, $config, $url;
            printf "papis-fzf :: DEBUG add.pm confirm_menu: tags: %s\n", join(" ", @tags);
            print  "papis-fzf :: DEBUG add.pm confirm_menu: colors: @colors\n";
            print  "papis-fzf :: DEBUG add.pm confirm_menu: hash keyname=>label :\n";
            print  "    $_ => $keylabel{$_}\n" foreach (keys %keylabel);
        }

    # Prints wrapped menu text
    print wrap("  ", "  ", $menutext) . "\n";

    my $key = readkey::readkey(); # Wait for user input
    my $ord = ord $key;

    return $key, $ord
}


=Gets action  ============================
  @_ : <context> <config> "key", ord
  returns : "action"
==========================================
=cut
sub action {
    my ($context, $config, $key, $ord, $hashref) = @_;
    my $action;

    # Gets %keyaction from the hash reference from parse_keymap
    my %keyaction = %$hashref;

    # 'Case' statement
    for ($key) {
        (exists $keyaction{$key}) and do { $action = $keyaction{$key}; last;};
        (exists $keyaction{$ord}) and do { $action = $keyaction{$ord}; last;};
        $action = 0;
    }

        # Debug
        if ($context->{debug}) {
            $key = "\\n" if ($key =~ m/\n/); # To show enter key
            $key = "\\e" if ($key =~ m/\e/); # To show esc
            printf "papis-fzf :: DEBUG add.pm action: key %s ord %s\n", $key, $ord;
            print  "papis-fzf :: DEBUG add.pm action: $action\n";
            print  "papis-fzf :: DEBUG add.pm action: hash key=>action :\n";
            print  "    $_ => $keyaction{$_}\n" foreach (keys %keyaction);
        }

    return $action
}

sub papis_add {
    my ($action, $context, $config, $logfile, $url, @tags) = @_;
    my $auto = ($config->{tags_auto}) ? 1 : 0;
    my $lasttags = $context->{cachedir} . "/add-last-tags";
    my $autoclear = ($config->{tags_auto_clear}) ? 1 : 0;

    # Current state of the papis library before adding a new directory
    my @before = `find '/home/archx/test' -mindepth 1 -type d`;

    # Edit specific options
    my $edit = ($action eq "edit") ? " --edit" : "";
    if ($action eq "edit") {
        my $editor = $config->{editor};      # gets the editor defined in the config
        $ENV{EDITOR} = $editor if ($editor); # sets the ENV editor var
    }

    # Set the papis command
    my $papiscmd = ($action eq 0) ? "papis add -b" : "papis add";
    $papiscmd .= sprintf " --set-after tags %s", join(" ", @tags) if (@tags);
    $papiscmd .= sprintf "%s %s 2>> %s", $edit, $url, $logfile;

#    mkdir "/home/archx/test/papis";

    if ($action eq 0) {
        print "papis add FIFO $context->{fifo}\n";
    } else {
        print "\npapis_NORMAL $papiscmd";
    }

    # If tags 'auto' setting if set in the config,
    #  add the last tags used to the $lasttags file
    if ($auto and @tags or $auto and $autoclear) {
        open FH, "+>", $lasttags or die "can't open $lasttags: $!";
            print FH "@tags";
        close FH or die "can't close $lasttags: $!";
    }
    # Gets the path of the new papis folders created
    my @after = `find '/home/archx/test' -mindepth 1 -type d`;

    my %old = map {$_=>1} @before;
    my @newdir = grep { !$old{$_} } @after;
    print "NEWDIR @newdir\n";
}


sub create_from_yaml {
    print "toto";
}


1;
