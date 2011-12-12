use common::sense;
use Test::More;
use AceCouch::Test::Util;

my $ac = connect();

my ($class, $name) = (Gene => 'WBGene00000018');
my $obj = $ac->fetch($class => $name);

my $tree;
subtest 'At on object, simple' => sub {
    my $tag = 'Gene_info';
    ok($tree = $obj->at($tag), 'Got subtree');
    ok($tree->tree, 'Subtree is tree');
    ok(! $tree->filled, 'Subtree is "unfilled"');
    is($tree->class, 'tag', 'Subtree has correct class');
    is($tree->name, $tag, 'Subtree has correct name');
};

subtest 'At on object, path' => sub {
    my @path = qw(Gene_info Ortholog_other);
    my $subtree = $obj->at(join '.', @path);
    ok($subtree, 'Got subtree');
    ok($subtree->tree, 'Subtree is tree');
    ok(! $subtree->filled, 'Subtree is "unfilled"');
    is($subtree->class, 'tag', 'Subtree has correct class');
    is($subtree->name, $path[-1], 'Subtree has correct name');
};

subtest 'At on tree, simple' => sub {
    my $tag = 'Ortholog_other';
    my $subtree = $tree->at($tag);
    ok($subtree, 'Got subtree');
    ok($subtree->tree, 'Subtree is tree');
    ok(! $subtree->filled, 'Subtree is "unfilled"');
    is($subtree->class, 'tag', 'Subtree has correct class');
    is($subtree->name, $tag, 'Subtree has correct name');
};

subtest 'At on tree, path' => sub {
    my @path = qw(Structured_description Provisional_description);
    my $subtree = $tree->at(join '.', @path);
    ok($subtree, 'Got subtree');
    ok($subtree->tree, 'Subtree is tree');
    ok(! $subtree->filled, 'Subtree is "unfilled"');
    is($subtree->class, 'tag', 'Subtree has correct class');
    is($subtree->name, $path[-1], 'Subtree has correct name');
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

done_testing;
