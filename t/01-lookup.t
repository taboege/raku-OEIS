use Test;
use OEIS;

use lib 't/lib';
use Test::OEIS;

plan 7;

subtest 'parse a single record' => {
    plan 3;

    my $ent;

    lives-ok {
        $ent = OEIS::Entry.parse(OEIS::chop-records slurp 't/data/A000045.txt');
    }, 'parsing a record works';

    is   $ent.ID,   'A000045', 'ID is correct';
    like $ent.name, / 'Fibonacci numbers' /, 'name is correct';
}

subtest 'parse many pages of records' => {
    plan 2;

    my @results;

    lives-ok {
        OEIS::chop-records(slurp 't/data/Fibonacci-Search-all.txt') ==>
            map { OEIS::Entry.parse($_) } ==> @results
    }, 'parsing a concatenation of pages works';

    cmp-ok @results, '==', 92, '92 entries parsed from search';
}

online -> {
    like OEIS::lookup(1, 1, * + * ... *).name,
    /^ 'Fibonacci numbers' /,
    "lookup Fibonacci Seq"
}

online -> {
    like OEIS::lookup(1, -3, -8, -3,-24, 24, -48).name,
    /^ 'Dirichlet inverse of the Jordan function J_2' /,
    "lookup Dirichlet inverse of J_2 list"
}

online -> {
    subtest "lookup Binary partitions by ID" => {
        plan 4;
        for 123, "A000123", "M1011", "N0378" {
            like OEIS::lookup(123).name,
            /^ 'Number of binary partitions: number of partitions of 2n into powers of 2' /,
            $_
        }
    }
}

online -> {
    cmp-ok +OEIS::lookup(90..105, :all), '>', 40,
    "pagination works"
}

online -> {
    cmp-ok +OEIS::lookup-all(1,2,3,6,11,23,47), '>', 11,
    "lookup-all works as well"
}
