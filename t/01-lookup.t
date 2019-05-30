use Test;
use OEIS;

use lib 't/lib';
use Test::OEIS;

plan 4;

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
