use common::sense;
use Test::More;
use Test::Exception;
use AceCouch;
use AceCouch::Test::Util;

my $ac = connect();

# real-world usage tests go here
subtest 'URI-unsafe names' => sub {
    my ($class, $name) = (Antibody => '[WBPaper00000345]:unc-54');
    my ($obj, @objs);

    subtest 'Scalar ctx ok' => sub {
        ok($obj = $ac->fetch($class => $name), 'Got object');
        is($obj->class, $class, 'Object class ok');
        is($obj->name, $name, 'Object name ok');
    };

    subtest 'List ctx ok' => sub {
        ok(@objs = $ac->fetch($class => $name), 'Got object');
        is($objs[0]->class, $class, 'Object class ok');
        is($objs[0]->name, $name, 'Object name ok');
    };

    my %params = (class => $class, name => $name);

    subtest 'Scalar ctx, fill ok' => sub {
        ok($obj = $ac->fetch(%params, filled => 1), 'Got object');
        is($obj->class, $class, 'Object class ok');
        is($obj->name, $name, 'Object name ok');
    };

    subtest 'List ctx, fill ok' => sub {
        ok(@objs = $ac->fetch(%params, filled => 1), 'Got object');
        is($objs[0]->class, $class, 'Object class ok');
        is($objs[0]->name, $name, 'Object name ok');
    };

    ## now with tags

    my $tag = 'Expression_cluster';
    %params = (class => 'Gene', name => 'WBGene00000018', tag => $tag);

  SKIP: {
        skip 'Exceptions disabled for ambiguous calls', 1 unless AceCouch::THROWS_ON_AMBIGUOUS;
        subtest 'Exception for ambiguous scalar ctx, tag' => sub {
            throws_ok { $obj = $ac->fetch(%params) } 'AC::E',
                'Exception thrown in scalar ctx for tag fetch with multiple objects';
            like $@, qr/ambiguous/i, 'Exception is ambiguous';
        };
    }

    {
        local $params{tag} = 'Legacy_information';
        ok($obj = $ac->fetch(%params), 'Scalar ctx, tag ok');
    };

    ok( ( @objs = $ac->fetch(%params) ) > 1, 'List ctx, tag ok' );

    $params{filled} = 1;

  SKIP: {
        skip 'Exceptions disabled for ambiguous calls', 1 unless AceCouch::THROWS_ON_AMBIGUOUS;
        subtest 'Exception for  ambiguous scalar ctx, tag, fill' => sub {
            throws_ok { $obj = $ac->fetch(%params) } 'AC::E',
                'Exception thrown in scalar ctx for tag&fill fetch with multiple objects';
            like $@, qr/ambiguous/i, 'Exception is ambiguous';
        };
    }

    # TODO:
    # subtest 'Scalar ctx, tag, fill ok' => sub {
    #     # criterion: need an object which has a tag with a single
    #     #            object with a weird ID
    # };

    ok( ( @objs = $ac->fetch(%params) ) > 1, 'List ctx, tag, fill ok' );
};

done_testing;
