use common::sense;
use Test::More;
use Test::Deep;
use AceCouch::Test::Util;

my $ac = connect();

my ($class, $name) = (Gene => 'WBGene00000018');

my $obj = $ac->fetch($class => $name);
my $filled_obj = $ac->fetch(
    class  => $class,
    name   => $name,
    filled => 1,
);

subtest 'Follow tag (scalar ctx)' => sub {
    my $tag = 'Interaction';
    isa_ok(my $interaction = $obj->$tag, 'AceCouch::Object');
    is($interaction->class, 'Interaction', 'Object class ok');
    cmp_deeply(
        $interaction->name,
        any(
            map { (my $a = $_) =~ s/^Interaction~//; $a }
            keys %{$filled_obj->data->{'tag~Experimental_info'}->{'tag~Interaction'}}
        )
    );
    ok(! $interaction->filled, 'Object unfilled');
};


subtest 'Follow tag, fill (scalar ctx)' => sub {
    my $tag = 'Interaction';
    isa_ok(my $interaction = $obj->$tag(-fill => 1), 'AceCouch::Object');
    is($interaction->class, 'Interaction', 'Object class ok');
    cmp_deeply(
        $interaction->name,
        any(
            map { (my $a = $_) =~ s/^Interaction~//; $a }
            keys %{$filled_obj->data->{'tag~Experimental_info'}->{'tag~Interaction'}}
        )
    );
    likely_filled_ok($interaction);
};

subtest 'Follow tag (list ctx)' => sub {
    my $tag = 'Interaction';
    my @interactions = $obj->$tag;
    ok(@interactions > 1, 'Followed multiple Interactions');
    subtest 'List of interactions ok' => sub {
        for my $i (@interactions) {
            isa_ok($i, 'AceCouch::Object');
            ok(! $i->filled, 'Interaction unfilled');
            is($i->class, 'Interaction', 'Object class ok');
        }
    };
};

subtest 'Follow tag, filled (list ctx)' => sub {
    my $tag = 'Interaction';
    my @interactions = $obj->$tag(-fill => 1);
    ok(@interactions > 1, 'Followed multiple Interactions');
    subtest 'List of interactions ok' => sub {
        for my $i (@interactions) {
            isa_ok($i, 'AceCouch::Object');
            is($i->class, 'Interaction', 'Object class ok');
            likely_filled_ok($i) or ddump($i);
        }
    };
};

my $tree;
subtest 'Follow tag, tree' => sub {
    my $tag = 'Gene_info';
    ok($tree = $obj->$tag(0), 'Followed Gene info');
    isa_ok($tree, 'AceCouch::Object');
    ok($tree->tree, 'Object is tree');
    ok(! $tree->filled, 'Object is unfilled');
    is($tree->class, 'tag', 'Class of tree ok');
    is($tree->name, 'Gene_info', 'Name of tree ok');
    is($tree->id, AceCouch->cn2id($tree->class, $tree->name), 'ID of tree ok');
};

subtest 'Col on tree' => sub {
    my @tags = $tree->col; # Gene_info column is full of tags
    ok(@tags > 1, 'Col got multiple objects');
    subtest 'List of objects ok' => sub {
        for my $t (@tags) {
            isa_ok($t, 'AceCouch::Object');
            ok(! $t->tree, 'Object is not tree');
            ok(! $t->filled, 'Object is unfilled');
            is($t->class, 'tag', 'Object is a tag');
        }
    };
};

subtest 'Col on unfilled obj' => sub {
    $obj = $ac->fetch($class => $name);
    ok(! $obj->filled, 'Object unfilled');
    my @tags = $obj->col; # column of Gene obj is full of tags
    ok( $obj->filled, 'Object filled');
    ok(@tags > 1, 'Col got multiple objects');
    subtest 'List of objects ok' => sub {
        for my $t (@tags) {
            isa_ok($t, 'AceCouch::Object');
            ok(! $t->tree, 'Object is not tree');
            ok(! $t->filled, 'Object is unfilled');
            is($t->class, 'tag', 'Object is a tag');
        }
    };
};

done_testing;
