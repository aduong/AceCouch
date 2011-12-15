package AceCouch::Object;

use common::sense;
use Carp qw(carp);
use AceCouch;
use AceCouch::Exceptions;
use List::Util qw(first);

use overload (
    '""'     => 'as_string',
    fallback => 'TRUE',
);

BEGIN {
    *as_string = \&name;
    *isClass   = \&isObject;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    my ($tag) = $AUTOLOAD =~ /.*::(.+)/;
    my $self = shift;

    $self = $self->fetch unless $self->isRoot;

    # acceptable arguments (mutex):
    # 1. position
    # 2. -fill TODO

    my $position;
    if (@_ == 1) {
        $position = shift;
    }

    return $self->get($tag, $position) if wantarray;

    my $obj = $self->get($tag, $position)
           // return;

    $obj->isObject ? $obj->fetch : $obj->right;
}

## specific constructors... mild code duplication for now

sub new_unfilled {
    my ($class, $db, $id) = @_;
    my ($c, $n) = AceCouch->id2cn($id);

    return bless { db => $db, id => $id, class => $c, name => $n }, $class;
}

sub new_filled {
    my ($class, $db, $id, $data) = @_;
    my ($c, $n) = AceCouch->id2cn($id);
    delete @{$data}{'class','name'};

    return bless {
        db     => $db,
        id     => $id,
        class  => $c,
        name   => $n,
        filled => 1,
        data   => $data,
    }, $class;
}

sub new_tree {
    my ($class, $db, $id, $data) = @_;
    my ($c, $n) = AceCouch->id2cn($id); # even trees have names and classes...
    delete @{$data}{'class','name'}; # just in case; probably not needed

    return bless {
        db    => $db,
        id    => $id,
        class => $c,
        name  => $n,
        tree  => 1,
        data  => $data,
    }, $class;
}

sub DESTROY {}

# a few things don't make sense if the object is a subtree

sub id     { shift->{id} }
sub name   { shift->{name} }
sub class  { shift->{class} }
sub data   { shift->{data} }
sub db     { shift->{db} }

# convention: filled and tree are mutually exclusive. filled
# AC::Objects should represent complete objects in the backend. tree
# AC::Objects should represent the root node of a subtree. trees, if
# their root node "isObject", should allow for stepping into the
# object via "fetch" or "fill".
sub filled { shift->{filled} }
sub tree   { shift->{tree} }

sub fill { # destructive. fills an unfilled object
    my $self = shift;

    if ( !$self->filled and $self->isObject) {
        my $filled = $self->db->fetch(
            class  => $self->class,
            name   => $self->name,
            filled => 1
        );
        %$self = %$filled;
    }

    return $self;
}

sub fetch { # destructive. fetches an unfilled object if tree
    my $self = shift;

    if ($self->tree and $self->isObject) {
        my $obj = $self->db->fetch(
            class  => $self->class,
            name   => $self->name,
        );
        %$self = %$obj;
    }

    return $self;
}

sub isRoot {
    my $self = shift;
    !$self->tree && $self->isObject;
}

sub isTag  { shift->class eq 'tag' }

sub isObject {
    my $self = shift;
    $self->db->isClass($self->class);
}

# works like AcePerl
sub col { # implicitly fills an object
    my $self = shift;
    my $pos = shift || 1;

    $self->fill unless $self->tree;

    my $data = $self->data;
    my @objs = ([ $self->id => $self->data ]);

    for (1..$pos) { # traverse level by level
        @objs = map {
            my $hash = $_->[1]; # this can be a hashref or null (undef)
            $hash ? map { [ $_ => $hash->{$_} ] } keys %$hash : ()
        } @objs;
    }

    return map {
        $_->[0] !~ /^_/ ? AceCouch::Object->new_unfilled($self->db, $_->[0]) : ();
    } @objs;
}

# works like AcePerl but won't support right on trees with more than
# one entry i.e. $tree->col > 1 (will throw exception instead of
# randomly returning a subtree)
sub right { # emulate via col
    my $self = shift;
    my $pos = shift // 1;

    $self->fill unless $self->tree; # if filled already, fill will return

    my ($id, $data) = ($self->id, $self->data);
    for (1..$pos) {
        my @obj_ids = grep { !/^_/ } keys %$data
            or return;

        if (@obj_ids > 1) {
            AC::E->throw('Ambiguous call to right; the call would return a psuedo-random object')
                if AceCouch->THROWS_ON_AMBIGUOUS;
            carp 'Ambiguous call to right; the call will return a pseudo-random object';
            $id = first { $data->{$_} } @obj_ids
                or return;
        }
        else {
            $id = $obj_ids[0];
        }

        $data = $data->{$id};
    }

    return AceCouch::Object->new_tree($self->db, $id, $data);
}

# works the same as AcePerl but does not (yet) support escaped . in path
# parts and will not support indices due to the inherent lack of order
sub at {
    my $self = shift;
    my $path = shift;

    return $self->right unless defined $path;

    $self->fill unless $self->tree; # if filled already, fill will return

    my ($subid, $subhash) = ($self->id, $self->data);
    for my $path_part (split /\./, $path) {
        $subid = "tag~$path_part";
        $subhash = $subhash->{$subid} or last;
    }

    return unless $subhash;

    if (wantarray) { # in list ctx, return subtrees to the right
        return map { AceCouch::Object->new_tree($self->db, $_, $subhash->{$_}) }
                   keys %$subhash;
    }

    return AceCouch::Object->new_tree($self->db, $subid, $subhash);
}

# works the same as AcePerl
sub tags {
    my $self = shift;

    $self->fill unless $self->tree;

    return map { s/tag~// and $_ or () }
           keys %{$self->data};
}

sub row {
    my $self = shift;

    $self->fill unless $self->tree;

    my @row;
    my $obj = $self;
    my $fetch;
    while ($obj) {
        # basically a clone + fetch:
        $fetch = AceCouch::Object->new_unfilled($obj->db, $obj->id);
        push @row, $fetch;
        eval { $obj = $obj->right };
        if (my $e = $@) { ref $e ? $e->rethrow : die $e }
    }

    return @row;
}

sub get { # only supporting positional index after tag
    my $self = shift;
    my $tag  = shift;
    my $position = shift;
    AC::E::Unimplemented->throw('Get does not (yet?) support non-positional args')
        if @_;

    my $db = $self->db;
    my $tree = $self->{cache}{tree}{$tag};
    unless (defined $tree) {
        if ($self->isRoot) { # don't do bfs, just query view
            $tree = eval {
                $db->fetch(
                    class => $self->class,
                    name  => $self->name,
                    tree  => 1,
                    tag   => $tag,
                )
            } or return;
        }
        else { # we're in a tree
            my @q = ($self->data);

            my $id = "tag~$tag";
            my $data;
            while ($data = shift @q) {
                next unless $data; # null or hashref
                if ($data->{$id}) {
                    $data = $data->{$id};
                    last;
                }
                push @q, values %$data;
            }

            return unless $data;
            $tree = AceCouch::Object->new_tree($db, $id, $data);
        }
        $self->_attach_tree($tag => $tree);
    }

    unless (defined $position) {
        return $tree unless wantarray;

        my $data = $tree->data;
        return map { AceCouch::Object->new_tree($db, $_, $data->{$_}) }
            keys %$data;
    }

    # oh boy, positional index provided

    my @data = ([ $self->id, $self->data ]);
    for (1..$position) {
        @data = map {
            my $hash = $_->[1];
            $hash ? map { [ $_ => $hash->{$_} ] } keys %$hash : ();
        } @data
        or return;
    }

    return map { AceCouch::Object->new_tree( $db, @$_ ) } @data if wantarray;

    if (@data > 1) {
        AC::E->throw('Ambiguous call to get with positional index; ' .
                     'the call would return a psuedo-random object')
          if AceCouch->THROWS_ON_AMBIGUOUS;
        carp 'Ambiguous call to get with positional index; '
           . 'the call will return a pseudo-random object';
    }

    return AceCouch::Object->new_tree( $db, @{$data[0]} );
}

sub _attach_tree {
    my ($self, $tag, $tree) = @_;

    $self->{cache}{tree}{$tag} = $tree;
    my $path = $self->db->get_path($self->class => $tag);
    my $hash = $self->{_data} //= {};

    $hash = $hash->{$_} = {} foreach @$path;

    $hash->{$tag} = $tree;
}

__PACKAGE__
