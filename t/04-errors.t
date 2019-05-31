use Test;
use OEIS;
use X::OEIS;

use lib 't/lib';
use Test::OEIS;

plan 5;

online -> {
    throws-like { OEIS::lookup 1,1 },
        X::OEIS::TooMany,
        'too many results for 1,1'
}

online -> {
    throws-like { OEIS::lookup 'seq:', 'xyzzy' },
        X::OEIS::Query,
        'malformed query throws';
}

throws-like { OEIS::Entry.parse('quux') },
    X::OEIS::Parser,
    'bogus response throws';

online -> {
    # If you have any ideas about this sequence, please let me know at
    # tobs@taboege.de. We stumbled on it in https://arxiv.org/abs/1902.11260
    lives-ok { OEIS::lookup(10, 142, 1166, 12796) },
        'no result is not an error';
}

online -> {
    # Hopefully someone will file an issue to this module when someone finds
    # out enough about it to add it to the OEIS :-)
    is OEIS::lookup-all(10, 142, 1166, 12796).elems, 0,
        'LUBF gaussoids remain mysterious';
}
