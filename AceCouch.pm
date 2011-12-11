package AceCouch;

use common::sense;
use AnyEvent::CouchDB;
use AceCouch::Object;
use AceCouch::Exceptions;
use URI::Escape;

sub new {
    my $class = shift;
    my %params = @_ == 1 ? %{$_[0]} : @_;

    my $self = {
        name => $params{name} // AC::E::RequiredArgument->throw('Need name of DB'),
        host => $params{host} // 'localhost',
        port => $params{port} // 5984,
    };

    $self->{_conn} = AnyEvent::CouchDB->new("http://$params{host}:$params{port}/");

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

    my $class = $params{class}
        // AC::E::RequiredArgument->throw('fetch requires "class" arg');
    my $name  = $params{name}
        // AC::E::RequiredArgument->throw('fetch requires "name" arg');

    # this will check for an underlying subdb
    my $db = $self->{_classdb}->{$class} //= $self->_connect($class);
    my $id = $params{id} // uri_escape("${class}~${name}");
        # should be abstracted into AceCouch::Object?

    # performance:
    # tag filled      2 reqs (view, bulk fetch if wantarray, otherwise fetch)
    # tag unfilled    2 reqs (view)
    # notag filled    1 req  (fetch)
    # notag unfilled  1 req  (head)

    if ($params{tag}) {
        my $view = ($params{tree} ? 'tree' : 'tag') . '/' . $params{tag};
        # if $params{tree}, then this is $obj->Tag(0)

        $view = $db->view($view, { key => $id })->recv->{rows}->[0]->{value};

        return AceCouch::Object->new_tree($self, "tag~$params{tag}", $view)
            if $params{tree};

        # not tree, so expect one or more objects depending on context

        my $obj_ids = $view;
        return unless @$obj_ids;

        # single object or not?
        unless (wantarray) {
            $id = $obj_ids->[0];

            return AceCouch::Object->new_unfilled($self, $id) unless $params{filled};

            $class = ($self->id2cn($id))[0];
            $db = $self->{_classdb}->{$class} //= $self->_connect($class);
            return AceCouch::Object->new_filled($self, $id, $db->open_doc($id)->recv);
        }

        # want many objects

        return map AceCouch::Object->new_unfilled($self, $_), @$obj_ids
            unless $params{filled};

        # will have to bulk fetch by class

        # first separate the objects by class (most of the time they're the same)

        my %objs_by_class;
        foreach (@$obj_ids) {
            push @{ $objs_by_class{ ($self->id2cn($_))[0] } }, $_;
        }

        return map {
            $db = $self->{_classdb}->{$class} //= $self->_connect($class);
            map {
                return unless defined $_->{doc} or $_->{class} eq 'tag';
                AceCouch::Object->new_filled($self, $_, $_->{doc});
            } @{ $db->open_docs( $objs_by_class{$class} )->recv->{rows} };
        } keys %objs_by_class;
    }

    # this is not fetching the tag of an object, but an object itself

    return AceCouch::Object->new_filled($self, $id, $db->open_doc($id)->recv)
        if $params{filled};

    # just want a "reference" to the object in the db

    # check if the object exists via HEAD
    my $response = $db->head(uri_escape($id))->recv
        or AC::E->throw(qq/Could not send HEAD for "$id"/);

    return unless $response->{Status} =~ /^2/; # object doesn't exist

    return AceCouch::Object->new_unfilled($self, $id);
}

sub id2cn {
    shift;
    split /~/, shift, 2
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
