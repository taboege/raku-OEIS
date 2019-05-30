use Test;
use OEIS;

plan 2;

todo "Not yet written";
nok "Make attribute tests";

with OEIS::lookup(1, 1, *+* ... *) {
    sub lookup-crossrefs (OEIS::Entry $seq) {
        $seq.crossrefs ==>
            map { .comb(/ 'A' \d ** 6 /).Slip } ==>
            map { OEIS::lookup($_) }
    }

    like lookup-crossrefs($_).head.name,
        / 'signed Fibonacci numbers' /,
        'lookup of crossrefs works';
}
