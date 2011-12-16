use common::sense;
use Test::More;
use AceCouch::Test::Util;

my $ac = connect();
# test subtree caching within the BFS.
my ($class, $name) = (Gene => 'WBGene00000018');
my $gene = $ac->fetch($class => $name);

my $start_tag = 'Identity';
# get all the paths for the gene class
$ac->get_path(Gene => $start_tag); # make the conn fetch the paths
my $pdoc = $ac->{_paths}->{Gene};
# merge the paths into a tree structure (multidimensional hash)

my $path_tree = {};
while (my ($k, $v) = each %$pdoc) {
    next if $k =~ /^_/;
    my $subtree = $path_tree;
    foreach (@$v) {
        $subtree = $subtree->{$_} //= {};
    }
    $subtree->{$k} = {};
}

{
    my $fetch_count = 0;
    my $orig = \&AceCouch::fetch;
    local *AceCouch::fetch = sub {
        ++$fetch_count;
        goto &$orig;
    };

    my $count = 0;
    # now do a BFS search on the path_tree starting at $start_tag

    my @q = ([ $start_tag => $path_tree->{$start_tag} ]);
    while (my $pair = shift @q) {
        ++$count;
        my ($k, $v) = @$pair;
        $gene->get($k);
        push @q, map { [ $_ => $v->{$_} ] } keys %$v;
    }

    ok($fetch_count < $count, 'Cached properly');
}

done_testing;
