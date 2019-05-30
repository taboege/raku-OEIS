use Test;
use Test::META;

plan 5;

meta-ok;

use-ok 'OEIS::Entry';
use-ok 'OEIS::Keywords';
use-ok 'X::OEIS';
use-ok 'OEIS';
