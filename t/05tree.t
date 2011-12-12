use common::sense;
use Test::More;
use Test::Deep;
use Test::Exception;
use AceCouch::Test::Util;

my $ac = connect();

my ($class, $name) = (Gene => 'WBGene00000018');
my $obj = $ac->fetch($class => $name);

my $tree;
subtest 'At on object, simple (scalar ctx)' => sub {
    my $tag = 'Gene_info';
    ok($tree = $obj->at($tag), 'Got subtree');
    ok($tree->tree, 'Subtree is tree');
    ok(! $tree->filled, 'Subtree is "unfilled"');
    is($tree->class, 'tag', 'Subtree has correct class');
    is($tree->name, $tag, 'Subtree has correct name');
};

subtest 'At on object, simple (list ctx)' => sub {
    my $tag = 'Gene_info';
    my @subtrees = sort $obj->at($tag);
    my @expected = sort $obj->$tag; # ?
    cmp_deeply(\@subtrees, \@expected, 'Result ok');
};

subtest 'At on object, path (scalar ctx)' => sub {
    my @path = qw(Gene_info Ortholog_other);
    my $subtree = $obj->at(join '.', @path);
    ok($subtree, 'Got subtree');
    ok($subtree->tree, 'Subtree is tree');
    ok(! $subtree->filled, 'Subtree is "unfilled"');
    is($subtree->class, 'tag', 'Subtree has correct class');
    is($subtree->name, $path[-1], 'Subtree has correct name');
};

subtest 'At on object, path (list ctx)' => sub {
    my @path = qw(Gene_info Ortholog_other);
    my $tag = $path[-1];
    my @subtrees = sort $obj->at(join '.', @path);
    my @expected = sort $obj->$tag; # ?
    cmp_deeply(\@subtrees, \@expected, 'Result ok');
};

subtest 'At on tree, simple (scalar ctx)' => sub {
    my $tag = 'Ortholog_other';
    my $subtree = $tree->at($tag);
    ok($subtree, 'Got subtree');
    ok($subtree->tree, 'Subtree is tree');
    ok(! $subtree->filled, 'Subtree is "unfilled"');
    is($subtree->class, 'tag', 'Subtree has correct class');
    is($subtree->name, $tag, 'Subtree has correct name');
};

subtest 'At on tree, simple (list ctx)' => sub {
    my $tag = 'Ortholog_other';
    my @subtrees = sort $tree->at($tag); # reminder: $tree = Gene_info tree
    my @expected = sort $obj->$tag;
    cmp_deeply(\@subtrees, \@expected, 'Result ok');
};

subtest 'At on tree, path (scalar ctx)' => sub {
    my @path = qw(Structured_description Provisional_description);
    my $subtree = $tree->at(join '.', @path);
    ok($subtree, 'Got subtree');
    ok($subtree->tree, 'Subtree is tree');
    ok(! $subtree->filled, 'Subtree is "unfilled"');
    is($subtree->class, 'tag', 'Subtree has correct class');
    is($subtree->name, $path[-1], 'Subtree has correct name');
};

subtest 'At on tree, path (list ctx)' => sub {
    my @path = qw(Structured_description Provisional_description);
    my $tag = $path[-1];
    my @subtrees = sort $tree->at(join '.', @path);
    my @expected = sort $obj->$tag;
    cmp_deeply(\@subtrees, \@expected, 'Result ok');
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

# subtest 'Right on object' => sub {} # no object...

subtest 'Right on tree' => sub {
    my $tag = 'RNAi_result';
    my $subtree = ($obj->$tag)[0];
    ok(my $evidence = $subtree->right, 'Got right');
    likely_tree_ok($evidence);
    is($evidence->class, 'tag', 'Subtree class ok');
    is($evidence->name, 'Inferred_automatically', 'Subtree name ok');
    is($evidence->id, AceCouch->cn2id('tag', 'Inferred_automatically'),
       'Subtree ID ok');
};

subtest 'Fetch on tree node' => sub {
    my $tag = 'RNAi_result';
    ok(my $subtree = ($obj->$tag)[0], 'Got tree node');
    is($subtree->class, 'RNAi', 'Node class ok');
    like($subtree->id, qr/^RNAi/, 'Node ID ok');
    likely_tree_ok($subtree);
    $subtree->fetch;
    ok(! $subtree->filled, 'Object is unfilled');
    ok(! $subtree->tree, 'Object is not tree');
    is($subtree->class, 'RNAi', 'Object class ok');
    like($subtree->id, qr/^RNAi/, 'Object ID ok');
};

throws_ok { $obj->row } 'AC::E', 'Row fails on multiple subtrees';

subtest 'Row on tree node' => sub {
    my $tag = 'Status';
    $tree = $obj->get($tag);
    my @row = $tree->row; # in the future, this may fail due to new data...
    ok(@row > 1, 'Got row ok') or ddump($tree, \@row);
};

$tree = $obj->at('Gene_info');

ok(! $tree->get('THIS_DOES_NOT_EXIST'), 'Invalid get on tree ok');

subtest 'Get on tree (scalar ctx)' => sub {
    my $tag = 'Structured_description';
    my $subtree = $tree->get($tag);
    ok($subtree, 'Got object ok');
    likely_tree_ok($subtree);
    is($subtree->class, 'tag', 'Object class ok');
    is($subtree->name, $tag, 'Object name ok');
};

subtest 'Get on tree (list ctx)' => sub {
    my $tag = 'Structured_description';
    my @subtrees = $tree->get($tag);
    ok(@subtrees, 'Got object(s) ok');
    subtest 'Objects ok' => sub {
        foreach (@subtrees) {
            likely_tree_ok($_);
            is($_->class, 'tag', 'Object class ok');
            isnt($_->name, $tag, 'Object name likely ok')
        }
    };
};

subtest 'Get on tree, >= 2 deep' => sub {
    my $tag = 'Provisional_description';
    ok(my $subtree = $tree->get($tag), 'Got object ok');
    likely_tree_ok($subtree);
    is($subtree->class, 'tag', 'Object class ok');
    is($subtree->name, $tag, 'Object name ok');
};

done_testing;
