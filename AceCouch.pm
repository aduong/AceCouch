package AceCouch;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {
        dbprefix => 'ws228_experimental_',
    }, $class;
}

sub get {
}

1;
