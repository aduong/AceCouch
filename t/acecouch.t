use common::sense;
use Test::More;
use Test::Exception;
use Test::Deep;
use AceCouch::Exceptions;

use_ok('AceCouch');

throws_ok { AceCouch->new } 'AC::E', 'Naked new throws';

my $ac = new_ok(
    'AceCouch' => [
        name => 'ws228_experimental',
        host => 'localhost',
        port => 5984,
    ]
);

my ($obj, $id, $class, $name, $tag);

($class, $name) = (Gene => 'WBGene00000018');
$id = "${class}_${name}";

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
        ok($data->{Gene_info}, 'Gene info present');
    };
};

my $filled_obj = $obj; # used to check tags

$tag = 'Gene_info';
subtest 'Fetch unfilled, scalar tag' => sub {
    $obj = $ac->fetch(
        class => $class,
        name  => $name,
        tag   => $tag,
    );
    isa_ok($obj, 'AceCouch::Object');
    ok(!$obj->filled, 'Object unfilled');
    cmp_deeply($obj->id, any(keys %{$filled_obj->data->{Gene_info}}),
               'Object id ok');
    my ($class, $name) = ($obj->class, $obj->name);
    ok($obj->id =~ /\Q$name\E/, 'Object name ok');
    ok($obj->class =~ /\Q$class\E/, 'Object class ok');
    is($obj->db, $ac, 'Object db ok');
};

done_testing;
