{
    package AD::Moose;
    use Moose;
    use namespace::autoclean;

    has foo => (
        isa => 'Str',
        is => 'rw',
    );

    __PACKAGE__->meta->make_immutable;
}
{
    package AD::NoMoose;

    sub new {
        my $class = shift;
        my %params = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

        my $self = {};
        $self{foo} = $params{foo} if $params{foo};

        bless $self, $class;
    }
}

use common::sense;
use Benchmark qw(cmpthese);

my $count = shift;
$count = eval "$count" || 10_000;

cmpthese($count, {
    Moose   => sub { AD::Moose->new(foo => 'abc') },
    NoMoose => sub { AD::NoMoose->new(foo => 'abc') },
});
