use common::sense;
use Test::More;
use Test::Exception;
use AceCouch;
use AceCouch::Test::Util;

my $ac;
my ($host, $port, $name) = ('dummy', 1337, 'test123');

sub conn_ok {
    is($ac->host, $host, 'Host ok');
    is($ac->port, $port, 'Port ok');
    is($ac->name, $name, 'DB name ok');
}

is(\&AceCouch::connect, \&AceCouch::new, 'connect is alias for new');

throws_ok { AceCouch->connect } 'AC::E::RequiredArgument',
    'Throws exception when trying to connect without a DB name';

ok($ac = AceCouch->connect(name => $name), 'Default connect ok');

$ac = AceCouch->connect(host => '0.0.0.0', port => 0, name => 'nowhere');
ok(!$ac->ping, 'Ping fail on non-existent server/DB');

ok($ac = AceCouch->connect(host => $host, port => $port, name => $name),
   'Connect ok with canonical arg keys');
conn_ok();

ok($ac = AceCouch->connect(-host => $host, -port => $port, -name => $name),
   'Connect ok with hyphen-prefixed arg keys');
conn_ok();

ok($ac = AceCouch->connect({ host => $host, port => $port, name => $name }),
   'Connect ok with hashref args');
conn_ok();

$ac = connect();
ok($ac->ping, 'Ping ok');
ok($ac->reopen, 'Reopen ok');

done_testing;

