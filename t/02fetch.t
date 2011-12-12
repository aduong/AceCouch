use common::sense;
use Test::More;
use Test::Deep;
use AceCouch::Test::Util;
use AceCouch;

my $ac = connect();

my ($class, $name, $id, $obj, $tag);

($class, $name) = (Gene => 'WBGene00000018');
$id = AceCouch->cn2id($class, $name);

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
    likely_filled_ok($obj);
};

my $filled_obj = $obj; # used to check tags

subtest 'Fetch unfilled, tag (scalar ctx)' => sub {
    $tag = 'Method';
    my $subobj = $ac->fetch(
        class => $class,
        name  => $name,
        tag   => $tag,
    );
    isa_ok($subobj, 'AceCouch::Object');
    ok(!$subobj->filled, 'Object unfilled');
    cmp_deeply($subobj->id, any(keys %{$filled_obj->data->{'tag~Method'}}),
               'Object id ok');
};

subtest 'Fetch filled, tag (scalar ctx)' => sub {
    my $subobj = $ac->fetch(
        class  => $class,
        name   => $name,
        tag    => $tag,
        filled => 1,
    );
    isa_ok($subobj, 'AceCouch::Object');
    ok($subobj->filled, 'Object filled');
    cmp_deeply($subobj->id, any(keys %{$filled_obj->data->{'tag~Method'}}),
               'Object id ok');
    is($subobj->db, $ac, 'Object db ok');
    likely_filled_ok($subobj);
};

done_testing;
