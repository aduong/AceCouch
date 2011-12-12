use common::sense;
use Test::More;
use AceCouch::Test::Util;
use AceCouch;

my $ac = connect();
my ($class, $name) = (Gene => 'WBGene00000018');

my $obj = $ac->fetch($class => $name);

ok(! $obj->filled, 'Object unfilled');

$obj->fill;
likely_filled_ok($obj);

$obj = $ac->fetch($class => $name);

$obj->fetch;
ok(! $obj->filled, 'Object unfilled when fetched');

done_testing;
