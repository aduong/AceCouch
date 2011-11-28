package AceCouch::Object;

use strict;
use warnings;

use AutoLoader 'AUTOLOAD';

sub AUTOLOAD {
    my ($pkg, $sub_name) = $AUTOLOAD =~ /(.+)::(.+)/;
    my $self = shift;

    $self->db->get(@_); # step into it
}

sub new {
    my ($class, $args) = @_;
    return bless $args, $class;
}

sub db {
    return $self->{db};
}

1;
