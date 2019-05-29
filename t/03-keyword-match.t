use Test;
use OEIS;
use OEIS::Keywords;

plan 2;

my @results = OEIS::lookup(1, 1, *+* ... *).head(20);

is +@results.grep(* ~~ nice),        1, 'nice';
is +@results.grep(* ~~ base & nonn), 6, 'base and nonn';
