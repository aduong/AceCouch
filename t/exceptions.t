use common::sense;
use Test::More;
use Test::Exception;
use AceCouch::Exceptions;

throws_ok { AC::E->throw(q/Help! I'm trapped in an exception!/) }
          'AceCouch::Exception', 'Generic error thrown';

throws_ok { AC::E::RequiredArgument->throw(q/Help! I'm trapped in an exception!/) }
          'AC::E::RequiredArgument', 'Required argument exception thrown';

done_testing;
