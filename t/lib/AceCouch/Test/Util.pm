package AceCouch::Test::Util;

use common::sense;
use AceCouch;
use Test::More;
use Exporter 'import';

our @EXPORT = qw(ddump connect likely_filled_ok);
our @EXPORT_OK;

sub connect {
    AceCouch->new(
        name => 'ws228',
        host => 'localhost',
        port => 5984,
    );
}

sub likely_filled_ok {
    my $obj = shift;
    subtest 'Object likely filled' => sub {
        ok($obj->filled, 'Object filled');
        is($obj->data->{_id}, $obj->id, 'Internal ID ok');
        ok($obj->data->{_rev}, 'Has internal revision');
    };
}

sub ddump {
    require Data::Dumper;
    diag(Data::Dumper::Dumper(@_));
}

__PACKAGE__
