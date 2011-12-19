use common::sense;
use Test::More;
use Test::Deep;
use Test::Exception;
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

throws_ok { $ac->raw_fetch } 'AC::E::RequiredArgument',
    'Raw fetch, exception thrown when missing arguments';

throws_ok { $ac->raw_fetch($obj) } 'AC::E::RequiredArgument',
    'Raw fetch, exception thrown when missing tag';

ok(!defined $ac->raw_fetch($obj, 'THIS_IS_NOT_A_TAG'), 'Raw fetch non-existent (fake) tag');

ok(!defined $ac->raw_fetch($obj, 'Molecular_name_for' ), 'Raw fetch data-less tag');

$tag = 'Experimental_info';
SKIP: {
    skip 'Will throw ambiguous exception', 1 if AceCouch::THROWS_ON_AMBIGUOUS;

    subtest 'Raw fetch tag, many (scalar ctx)' => sub {
        $tag = 'Experimental_info';
        my $val = $ac->raw_fetch($obj, $tag);
    };
}

subtest 'Raw fetch tag, single (scalar ctx)' => sub {
    $tag = 'Method';
    ok(my $val = $ac->raw_fetch($obj,$tag), 'Fetched a value');
    unlike($val, qr/^Method~/, 'Value has class removed');
};

subtest 'Raw fetch tag (list ctx)' => sub {
    $tag = 'Experimental_info';
    ok( ( my @tags = $ac->raw_fetch($obj, $tag) ) > 1, 'Fetched multiple values');
    is(scalar( grep { !/^tag~/ } @tags ), scalar @tags, 'Values have classes removed');
};

done_testing;
