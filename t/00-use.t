use Test;
use Test::META;

plan 4;

meta-ok;

use-ok 'OEIS';
use-ok 'OEIS::Entry';
use-ok 'OEIS::Keywords';
