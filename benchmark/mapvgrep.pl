use common::sense;
use Benchmark qw(cmpthese);

my @super_tiny_list = (0,1,0,1,0,1);
my @tiny_list       = ((0)x10, (1)x10);
my @small_list      = ((0)x100, (1)x100);
my @big_list        = ((0)x1000, (1)x1000);

my $count = -5;

cmpthese($count, {
    super_tiny_map  => sub { map { return unless $_; $_ ** 3 } @super_tiny_list },
    super_tiny_grep => sub { map { $_ ** 3 } grep { $_ } @super_tiny_list },
});

cmpthese($count, {
    tiny_map  => sub { map { return unless $_; $_ ** 3 } @tiny_list },
    tiny_grep => sub { map { $_ ** 3 } grep { $_ } @tiny_list },
});

cmpthese($count, {
    small_map  => sub { map { return unless $_; $_ ** 3 } @small_list },
    small_grep => sub { map { $_ ** 3 } grep { $_ } @small_list },
});

cmpthese($count, {
    big_map  => sub { map { return unless $_; $_ ** 3 } @big_list },
    big_grep => sub { map { $_ ** 3 } grep { $_ } @big_list },
});
