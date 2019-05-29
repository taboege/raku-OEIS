use Test;
use OEIS;

plan 7;

like OEIS::lookup(1, 1, * + * ... *).name,
    /^ 'Fibonacci numbers' /,
    "lookup Fibonacci Seq";

like OEIS::lookup(1, -3, -8, -3,-24, 24, -48).name,
    /^ 'Dirichlet inverse of the Jordan function J_2' /,
    "lookup Dirichlet inverse of J_2 list";

like OEIS::lookup(123).name,
    /^ 'Number of binary partitions: number of partitions of 2n into powers of 2' /,
    "lookup Binary partitions by ID";

like OEIS::lookup("A000123").name,
    /^ 'Number of binary partitions: number of partitions of 2n into powers of 2' /,
    "lookup Binary partitions by A-ID";

like OEIS::lookup("M1011").name,
    /^ 'Number of binary partitions: number of partitions of 2n into powers of 2' /,
    "lookup Binary partitions by M-ID";

like OEIS::lookup("N0378").name,
    /^ 'Number of binary partitions: number of partitions of 2n into powers of 2' /,
    "lookup Binary partitions by N-ID";

cmp-ok +OEIS::lookup(90..105, :all), '>', 40,
    "pagination works";
