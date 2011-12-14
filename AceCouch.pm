package AceCouch;

use common::sense;
use AnyEvent::CouchDB;
use AceCouch::Object;
use AceCouch::Exceptions;
use URI::Escape::XS qw(uri_escape);
use Carp qw(carp);

our $VERSION = 0.95;

our $THROWS_ON_AMBIGUOUS;
BEGIN {
    $THROWS_ON_AMBIGUOUS //= 1;
    $THROWS_ON_AMBIGUOUS = !! $THROWS_ON_AMBIGUOUS;
}

use constant THROWS_ON_AMBIGUOUS => $THROWS_ON_AMBIGUOUS;

BEGIN {
    *connect = \&new;
}

my %nonclass = map { $_=>1 }
    qw(float int date tag txt peptide dna scalar text Text comment);

sub new {
    my $class = shift;
    my %params = @_ == 1 ? %{$_[0]} : @_;

    my $self = {
        name => $params{name} // AC::E::RequiredArgument->throw('Need name of DB'),
        host => $params{host} // 'localhost',
        port => $params{port} // 5984,
    };

    $self->{_conn} = AnyEvent::CouchDB->new("http://$self->{host}:$self->{port}/");

    return bless $self, $class;
}

sub name { shift->{name} }
sub host { shift->{host} }
sub port { shift->{port} }

# class, name, filled (bool), tag
sub fetch {
    my $self = shift;

    my %params = @_ > 2    ? @_
               : @_ == 2   ? (class => $_[0], name => $_[1])
               : ref $_[0] ? %{$_[0]}
               : do {
                   my ($c,$n) = $self->id2cn($_[0]);
                   (class => $c, name => $n);
                 };

    foreach (qw(class name tag filled tree)) { # AcePerl interface... might remove later
        $params{$_} //= $params{"-$_"};
    }

    my $class = $params{class}
        // AC::E::RequiredArgument->throw('fetch requires "class" arg');
    my $name  = $params{name}
        // AC::E::RequiredArgument->throw('fetch requires "name" arg');

    # this will check for an underlying subdb
    my $db = $self->{_classdb}->{$class} //= $self->_connect($class);
    my $id = $params{id} // $self->cn2id($class, $name);
        # should be abstracted into AceCouch::Object?

    if ($params{tag}) {
        my $view = ($params{tree} ? 'tree' : 'tag') . '/' . $params{tag};
        # if $params{tree}, then this is $obj->Tag(0)

        $view = $db->view($view, { key => uri_escape($id) })->recv->{rows}->[0]->{value};

        return AceCouch::Object->new_tree($self, "tag~$params{tag}", $view)
            if $params{tree};

        # not tree, so expect one or more objects depending on context

        my $obj_ids = $view;
        return unless @$obj_ids;

        # single object or not?
        unless (wantarray) { # single
            if (@$obj_ids > 1) {
                AC::E->throw('Ambiguous fetch; the fetch would result in a random object')
                    if THROWS_ON_AMBIGUOUS;
                carp 'Ambiguous fetch; the fetch will result in a random object';
            }

            $id = $obj_ids->[0];

            return AceCouch::Object->new_unfilled($self, $id) unless $params{filled};

            $class = ($self->id2cn($id))[0];
            $db = $self->{_classdb}->{$class} //= $self->_connect($class);
            return AceCouch::Object->new_filled(
                $self, $id, $db->open_doc( uri_escape($id) )->recv
            );
        }

        # want many objects

        return map AceCouch::Object->new_unfilled($self, $_), @$obj_ids
            unless $params{filled};

        # will have to bulk fetch by class

        # first separate the objects by class (most of the time they're the same)

        my %objs_by_class;
        foreach (@$obj_ids) {
            push @{ $objs_by_class{ ($self->id2cn($_))[0] } }, uri_escape($_); # problem area
        }

        return map {
            # FIXME: problems when class is not an Object class
            my $class = $_;
            $db = $self->{_classdb}->{$class} //= $self->_connect($class);
            map {
                defined $_->{doc} ?
                     AceCouch::Object->new_filled($self, $_->{id}, $_->{doc}) : ()
            } @{ $db->open_docs( $objs_by_class{$class} )->recv->{rows} };
        } keys %objs_by_class;
    }

    # this is not fetching the tag of an object, but an object itself

    return AceCouch::Object->new_filled($self, $id, $db->open_doc( uri_escape($id) )->recv)
        if $params{filled};

    # just want a "reference" to the object in the db

    # check if the object exists via HEAD
    my $response = $db->head( uri_escape( uri_escape($id) ) )->recv
        or AC::E->throw(qq/Could not send HEAD for "$id"/);

    return unless $response->{Status} =~ /^2/; # object doesn't exist

    return AceCouch::Object->new_unfilled($self, $id);
}

sub cn2id {
    shift;
    "$_[0]~$_[1]";
}

sub id2cn {
    shift;
    split /~/, shift, 2
}

sub isClass {
    shift;
    ! $nonclass{$_[0]};
}

sub version {
    return "AceCouch v$VERSION";
}

sub _connect {
    my ($self, $class) = @_;
    my $dbs = $self->{_conn}->all_dbs->recv;

    my $dbname = $self->name . lc "_$class";
  DBEXISTS: {
        foreach (@$dbs) {
            last DBEXISTS if $dbname eq $_;
        }
        AC::E::UnknownClass->throw($class . ' is an unknown class in the database');
    }

    return $self->{_conn}->db($dbname);
}

__PACKAGE__
