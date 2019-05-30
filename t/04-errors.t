use Test;
use OEIS;
use X::OEIS;

plan 4;

throws-like { OEIS::lookup 1,1 }, X::OEIS::TooMany, 'too many results for 1,1';
throws-like { OEIS::lookup 'seq:', 'xyzzy' }, X::OEIS::Query, 'malformed query throws';
throws-like { OEIS::Entry.parse-oeis('frubby') }, X::OEIS::Parser, 'bogus response throws';
# If you have any ideas about this sequence, please let me know at
# tobs@taboege.de. We stumbled on it in https://arxiv.org/abs/1902.11260
lives-ok { OEIS::lookup(10, 142, 1166, 12796) }, 'no result is not an error';
