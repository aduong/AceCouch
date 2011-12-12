use common::sense;
use Test::More;
use Test::Exception;
use AceCouch::Exceptions;

throws_ok { AceCouch::Exception->throw } 'AceCouch::Exception', 'Exception thrown';
throws_ok { AC::E->throw } 'AC::E', 'Exception (alias) thrown';

for (qw(RequiredArgument UnknownClass Unimplemented)) {
    my $eclass = 'AC::E::' . $_;
    throws_ok { $eclass->throw } $eclass, "$eclass thrown";
}

done_testing;
