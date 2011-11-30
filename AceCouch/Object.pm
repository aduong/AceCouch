package AceCouch::Object;

use common::sense;

use overload (
    '""'       => 'as_string',
    'fallback' => 'TRUE',
);

BEGIN { *as_string = \&name; }

sub AUTOLOAD {
    our $AUTOLOAD;
    my ($tag) = $AUTOLOAD =~ /.*::(.+)/;
    my $self = shift;
    # TODO: fill & tree

    return $self->db->fetch(
        class  => $self->class,
        name   => $self->name,
        tag    => $tag,
    );
}

sub new {
    my ($class, $args) = @_;
    return bless $args, $class;
}

sub id     { shift->{id} }
sub name   { shift->{data}{name} }
sub class  { shift->{data}{class} }
sub data   { shift->{data} }
sub filled { shift->{filled} }
sub db     { shift->{db} }

1;
