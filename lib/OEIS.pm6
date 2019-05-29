=begin pod

=head1 NAME

OEIS - Look up sequences on the On-Line Encyclopedia of Integer Sequences®

=head1 SYNOPSIS

=begin code
use OEIS;

say OEIS::lookup 1, 1, * + * ... *
#= OEIS A000045 «Fibonacci numbers: F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1.»
=end code

=head1 DESCRIPTION

This module provides an interface to the L<On-Line Encyclopedia of Integer Sequences® (OEIS®)|https://oeis.org>,
a web database of integer sequences. Stick an array or Seq into the C<OEIS::lookup>
routine and get back a lazy Seq of all search results as instances of C<OEIS::Entry>.

=end pod

unit module OEIS;

use WWW;

use OEIS::Entry;

# Put OEIS::Keywords constants under the OEIS:: package.You can get them
# directly into your current package by requiring OEIS::Keywords, but since
# it contains names such as `base`, this is not recommended.
for OEIS::Keyword::.kv -> $key, $value {
    OEIS::«$key» = $value
}

sub lookup'paginated ($base-url) {
    my $start = 0;
    my $top-id = -Inf;
    gather PAGE: loop {
        # If the $start argument is too big, OEIS will return
        # the last page again and again. Since the results are
        # in "relevance order", we can't use monotonicity.
        # Instead remember the first ID seen on the previous
        # page and stop if it repeats.
        for OEIS::Entry.parse-oeis(get "$base-url&start=$start") {
            FIRST {
                last PAGE if $top-id == .ID;
                $top-id = .ID;
            }

            $start++;
            take .self;
        }
    }
}

our sub lookup (:$all = False, |c) {
    my \seq = lookup'multi |c;
    $all ?? seq !! seq.first
}

#| Look up a sequence by its OEIS ID, e.g. 123 for "A000123".
multi lookup'multi (Int $ID, :$type = 'A') {
    lookup'paginated qq<https://oeis.org/search?q=id:{ $type ~ $ID.fmt("%06d") }&fmt=text>
}

#| Look up a sequence by its stringified OEIS ID, e.g. "A000123".
multi lookup'multi (Str $ID where * ~~ /^ $<type>=<[AMN]> <( \d+ )> $/) {
    samewith +$/, :$<type>
}

#| Look up the sequence from a Seq producing it.
multi lookup'multi (Seq $seq) {
    # XXX: How to choose the sample size? Too few and we get too many
    # results, which is not critical but can push the really relevant
    # sequence away from the top of the results. Too many may use lots
    # of time to compute and memory to store (e.g. with double exponential
    # growth in the Seq) and the OEIS might return too few results because
    # they don't have that many terms themselves.
    my @partial-seq = $seq[^8];
    samewith @partial-seq
}

#| Look up a sequence from some of its members.
multi lookup'multi (*@partial-seq) {
    lookup'paginated qq<https://oeis.org/search?q={ @partial-seq.join(',') }&fmt=text>
}

=begin pod

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2018/9 Tobias Boege

This library is free software; you can redistribute it
and/or modify it under the Artistic License 2.0.

=end pod
