=config.pm  ==========================
  Parse config file
  Constitute a <config> object,
   listing pairs of key/value settings
  The config file has the format:
    key=value
  The value can be writed on several lines,
   if these lines
  To get a value:
    $config->{key}
======================================
=cut
package config;
use strict;
use warnings;

sub parse_config {
    my $class = shift;
    my $configfile = shift . "/config";

    my $self = {}; my ($key, $value);
    open C, "<", $configfile or die "can't open $configfile: $!";
        while (<C>){
            # Ignores empty and commented lines
            if (not /^#/ and not /^$/) {
                chomp;
                if (/^\S*?=/) {
                  # line: ^[word_with_no_=_&_no_spaces]=.*
                  #  => a key !
                    ($key, $value) = split "=", $_, 2;
                    $self->{$key} = $value;
                } else {
                  # a line which does'nt contain a key
                  #  (starts by a space, is not empty)
                  #  => update value
                    $value .= $_;            # appends value
                    $value =~ s/ +/ /g;  # gets rid of multiple whitespaces
                    $self->{$key} = $value;  # appends key value
                }
            }
        }
    close C or die "can't close $configfile: $!";

    bless $self, $class;
    return $self;
}

1;
