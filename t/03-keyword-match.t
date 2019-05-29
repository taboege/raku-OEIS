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

    my @results = OEIS::lookup((1, 1, *+* ... *), :all).head(20);
    is +@results.grep(* ~~ nice),        1, '1x nice';
    is +@results.grep(* ~~ base & nonn), 6, '6x base and nonn';
    like OEIS::lookup((1, 1, *+* ... *), :all).first(* !~~ easy).name,
        /^ 'Number of transitive rooted trees with n nodes' /,
        "first non-easy result";
}
