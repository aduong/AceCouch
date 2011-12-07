use common::sense;
use Test::More;
use Test::Exception;
use Test::Deep;
use AceCouch::Exceptions;

use_ok('AceCouch');

throws_ok { AceCouch->new } 'AC::E', 'Naked new throws';

my $ac = new_ok(
    'AceCouch' => [
        name => 'ws228',
        host => 'localhost',
        port => 5984,
    ]
);

my ($obj, $id, $class, $name, $tag);

($class, $name) = (Gene => 'WBGene00000018');
$id = "${class}~${name}";

subtest 'Fetch unfilled object' => sub {
    isa_ok($obj = $ac->fetch($class => $name), 'AceCouch::Object');
    ok(!$obj->filled, 'Object unfilled');
    is($obj->id, $id, 'Object id ok');
    is($obj->name, $name, 'Object name ok');
    is($obj->class, $class, 'Object class ok');
    is($obj->db, $ac, 'Object db ok');
};

subtest 'Fetch filled object' => sub {
    $obj = $ac->fetch(
        class  => $class,
        name   => $name,
        filled => 1,
    );
    isa_ok($obj, 'AceCouch::Object');
    ok($obj->filled, 'Object filled');
    is($obj->id, $id, 'Object id ok');
    is($obj->name, $name, 'Object name ok');
    is($obj->class, $class, 'Object class ok');
    is($obj->db, $ac, 'Object db ok');
    subtest 'Object content seems ok' => sub {
        my $data = $obj->data;
        is($data->{_id}, $id, 'Internal id ok');
        ok($data->{_rev}, 'Rev present');
        ok($data->{'tag~Gene_info'}, 'Gene info present');
    };
};

my $filled_obj = $obj; # used to check tags
my $subobj;

$tag = 'Method';
subtest 'Fetch unfilled, scalar tag' => sub {
    $subobj = $ac->fetch(
        class => $class,
        name  => $name,
        tag   => $tag,
    );
    isa_ok($subobj, 'AceCouch::Object');
    ok(!$subobj->filled, 'Object unfilled');
    cmp_deeply($subobj->id, any(keys %{$filled_obj->data->{'tag~Method'}}),
               'Object id ok');
    my ($class, $name) = ($subobj->class, $subobj->name);
    ok($subobj->id =~ /\Q$name\E/, 'Object name ok');
    ok($subobj->class =~ /\Q$class\E/, 'Object class ok');
    is($subobj->db, $ac, 'Object db ok');
};

subtest 'Fetch filled, scalar tag' => sub {
    $subobj = $ac->fetch(
        class  => $class,
        name   => $name,
        tag    => $tag,
        filled => 1,
    );
    isa_ok($subobj, 'AceCouch::Object');
    ok($subobj->filled, 'Object filled');
    cmp_deeply($subobj->id, any(keys %{$filled_obj->data->{'tag~Method'}}),
               'Object id ok');
    my ($class, $name) = ($subobj->class, $subobj->name);
    ok($subobj->id =~ /\Q$name\E/, 'Object name ok');
    ok($subobj->class =~ /\Q$class\E/, 'Object class ok');
    is($subobj->db, $ac, 'Object db ok');
};

$tag = 'GFF_feature';
subtest 'Follow tag' => sub {
    my $subobj = $subobj->$tag; # lexical
    isa_ok($subobj, 'AceCouch::Object');
    ok(! $subobj->filled, 'Object filled');
};

$tag = 'Allele';
subtest 'Follow tag, scalar' => sub {
    my @subobjs = $obj->$tag;
    ok(@subobjs, 'Got at least one object');

    foreach (@subobjs) {
        isa_ok($_, 'AceCouch::Object');
        is($_->class, 'Variation', 'Object class ok');
        ok(! $_->filled, 'Object unfilled');
        is($_->db, $ac, 'Object db ok');
    }
};

done_testing;

sub ddump {
    require Data::Dumper;
    diag(Data::Dumper::Dumper(@_));
}
