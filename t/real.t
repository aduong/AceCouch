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
    my %params = (class => $class, name => $name);

    ok($obj = $ac->fetch(%params), 'Scalar ctx ok');
    ok(@objs = $ac->fetch(%params), 'List ctx ok');

    $params{filled} = 1;

    ok($obj = $ac->fetch(%params), 'Scalar ctx, fill ok');
    ok(@objs = $ac->fetch(%params), 'List ctx, fill ok');

    undef $params{filled};
    $params{tag} = 'Gene';

    ok($obj = $ac->fetch(%params), 'Scalar ctx, tag ok');
    ok(@objs = $ac->fetch(%params), 'List ctx, tag ok');

    $params{filled} = 1;

    ok($obj = $ac->fetch(%params), 'Scalar ctx, tag, fill ok' );
    ok(@objs = $ac->fetch(%params), 'List ctx, tag, fill ok' );

    # strange object in tag

    $params{tag} = 'Possible_pseudonym_of';

    ok($obj = $ac->fetch(%params), 'Scalar ctx, tag, fill ok (unsafe target)' );
    ok(@objs = $ac->fetch(%params), 'List ctx, tag, fill ok (unsafe target)' );
};

subtest 'Get protein peptide data' => sub {
    my ($class, $name) = (Protein => 'WP:CE04538');
    ok(my $protein = $ac->fetch($class => $name), 'Got protein');
    ok(my $peptide = $protein->Peptide(2), 'Got Peptide(2)');
};

done_testing;
