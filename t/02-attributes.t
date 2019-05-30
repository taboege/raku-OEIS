use Test;
use OEIS;

use lib 't/lib';
use Test::OEIS;

plan 30;

my $seq := 0, 1, 1, * + * ... *;
my $ent;

lives-ok { $ent = OEIS::Entry.parse(OEIS::chop-records slurp 't/data/A000045.txt') },
    'parsing A000045.txt file succeeds';

given $ent {
    cmp-ok .ID,  '==',       45,  'ID numerically 45';
    cmp-ok .ID,  'eq', 'A000045', 'ID stringly A000045';
    cmp-ok .MID, '==',      692,  'MID numerically 692';
    cmp-ok .MID, 'eq',   'M0692', 'MID stringly M0692';
    cmp-ok .NID, '==',      256,  'NID numerically 256';
    cmp-ok .NID, 'eq',   'N0256', 'NID stringly N0256';

    cmp-ok .sequence, '>', 40, 'many sequence elements';
    is-deeply .sequence, $seq[^+.sequence].&(Array[Int]),
        'sequence is correct';

    like .name, /^ 'Fibonacci numbers' /, 'name is Fibonacci numbers';

    cmp-ok .references, '>', 50, 'many references';
    cmp-ok .references.grep(/Springer/), '==', 5, '5x Springer references';

    cmp-ok .links, '>', 100, 'many links';
    cmp-ok .links.grep(/Computer/), '==', 2, '2x Computer-related links';

    cmp-ok .formulas, '>', 100, 'many formulas';
    cmp-ok .formulas.grep(/201<[5678]>$/), '==', 11, '11x formulas added 2015-2018';

    sub get-crossrefs (OEIS::Entry $ent) {
        $ent.crossrefs ==> map { .comb(/ 'A' \d ** 6 /).Slip }
    }

    cmp-ok get-crossrefs($_), '==', 74, 'many crossrefs';
    online -> {
        with OEIS::lookup(1, 1, *+* ... *) {
            sub lookup-crossrefs (OEIS::Entry $ent) {
                get-crossrefs($ent) ==> map { OEIS::lookup($_) }
            }

            like lookup-crossrefs($_).head.name,
                / 'signed Fibonacci numbers' /,
                'lookup of crossrefs works';
        }
    }

    like .author, /Sloane/, 'author is Sloane';

    is .start-arg, 0, 'start-arg is 0';
    is .offset,    4, 'offset is 4';

    cmp-ok .maple, '==', 5, '5 lines of Maple';
    cmp-ok .mathematica, '==', 5, '5 lines of Mathematica';
    cmp-ok .programs, '==', 70, '70 lines of other programs';
    cmp-ok .programs.grep(*.starts-with: '(PARI)'), '==', 4,
        '4 lines of PARI programs';
    cmp-ok .programs.grep(/ '(PARI)' .* 'Greathouse' /), '==', 1,
        'one of them by Charles Greathouse';

    cmp-ok .errata, '==', 0, 'no errata';

    cmp-ok .examples.elems, '==', 33, '33x examples';

    cmp-ok .keywords, '⊇', set(OEIS::nice, OEIS::easy, OEIS::nonn),
        'keywords include nice, easy, nonn';

    cmp-ok .comments, '>', 150, 'many comments';
}
