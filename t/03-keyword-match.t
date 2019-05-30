use Test;
use OEIS;

plan 3;

subtest "keywords are available in OEIS::" => {
    plan 2;

    isa-ok OEIS::nonn, OEIS::Keyword;
    isa-ok OEIS::nice, OEIS::Keyword;
}

subtest "direct import of keywords" => {
    plan 2;
    use OEIS::Keywords;

    isa-ok nonn, OEIS::Keyword;
    isa-ok nice, OEIS::Keyword;
}

subtest "smartmatching works" => {
    plan 3;
    use OEIS::Keywords;

    my @results = OEIS::chop-records(slurp 't/data/Fibonacci-Search-all.txt')\
        .map({ OEIS::Entry.parse($_) })\
        .head(20);
    cmp-ok @results.grep(* ~~ nice),        '==', 1, '1x nice';
    cmp-ok @results.grep(* ~~ base & nonn), '==', 6, '6x base and nonn';
    like @results.first(* !~~ easy).name,
        /^ 'Number of transitive rooted trees with n nodes' /,
        "first non-easy result";
}
