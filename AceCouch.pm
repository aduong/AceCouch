package AceCouch;

use common::sense;
use Try::Tiny;
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
                   my ($c,$n) = split /~/, $_[0];
                   (class => $c, name => $n);
                 };

    my $class = $params{class}
        // AC::E::RequiredArgument->throw('fetch requires "class" arg');
    my $name  = $params{name}
        // AC::E::RequiredArgument->throw('fetch requires "name" arg');

    # this will check for an underlying subdb
    my $db = $self->{_classdb}->{$class} //= $self->_connect($class);
    my $id = uri_escape("${class}~${name}");
        # should be abstracted into AceCouch::Object?

    # performance:
    # tag filled      2 reqs (view, bulk fetch)
    # tag unfilled    2 reqs (view, bulk fetch)
    # notag filled    1 req  (fetch)
    # notag unfilled  1 req  (head)

    if (defined $params{tag}) {
        # prepare args for querying view
        my @args = ( "\L$class\E/$params{tag}",
                     { key => [ $id, $class, $name ] } );

        my @obj_ids = map { $_->{value} } @{ $db->view(@args)->recv->{rows} };
        @obj_ids = ($obj_ids[0]) if !wantarray && @obj_ids;

        # prepare for opening docs
        @args = (\@obj_ids, { include_docs => $params{filled} });

        # this can be optimized for single document fetches (get vs post)
        return map {
            AceCouch::Object->new({
                db     => $self,
                id     => $_->{doc}{_id},
                data   => $_->{doc},
                filled => $params{filled},
            });
        } @{ $db->open_docs(@args)->recv->{rows} };
    }

    if ($params{filled}) {
        return AceCouch::Object->new({
            db     => $self,
            id     => $id,
            data   => $db->open_doc($id)->recv,
            filled => 1
        });
    }

    # just want a "reference" to the object in the db

    # check if the object exists via HEAD
    my $response = $db->head(uri_escape($id))->recv
        or AC::E->throw(qq/Could not send HEAD for "$id"/);

    return unless $response->{Status} =~ /^2/; # object doesn't exist

    return AceCouch::Object->new({
        db     => $self,
        id     => $id,
        filled => undef,
        data   => {
            name  => $name,
            class => $class,
        }
    });
}

sub _connect {
    my ($self, $class) = @_;
    my $dbs = try   { $self->{_conn}->all_dbs->recv }
              catch { ref $_ ? $_->rethrow : die $_ };

    my $dbname = $self->name . "_\L$class";
  DBEXISTS: {
        foreach (@$dbs) {
            last DBEXISTS if $dbname eq $_;
        }
        AC::E::UnknownClass->throw($class . ' is an unknown class in the database');
    }

    return $self->{_conn}->db($dbname);
}

1;
