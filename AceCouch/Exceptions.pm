package AceCouch::Exceptions;

use common::sense;
use Exception::Class (
    'AceCouch::Exception',
    'AC::E' => { # alias
        isa => 'AceCouch::Exception',
        description => 'Generic/unknown exception',
    },
    'AC::E::RequiredArgument' => {
        isa         => 'AC::E',
        description => 'Argument required',
    },
    'AC::E::UnknownClass' => {
        isa         => 'AC::E',
        description => 'Class could not be found',
    },
    'AC::E::Unimplemented' => {
        isa         => 'AC::E',
        description => 'Unimplemented feature',
    },
);

AceCouch::Exception->Trace(1);
AC::E->Trace(1);

__PACKAGE__
