use common::sense;

use Benchmark qw(cmpthese);

cmpthese(10_000_000, {
    unpack     => sub { a(1) },
    shift      => sub { b(1) },
    shift_var  => sub { c(1) },
    direct     => sub { d(1) },
    direct_var => sub { e(1) },
});

sub a { my ($a) = @_; $a+2 }
sub b { 2+shift }
sub c { my $a = shift; $a+2 }
sub d { $_[0] + 2 }
sub e { $a = $_[0]; $a + 2 }
