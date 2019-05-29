=begin pod

=head1 NAME

OEIS - Look up sequences on the On-Line Encyclopedia of Integer Sequences®

=head1 SYNOPSIS

=begin code
use OEIS;

say OEIS::lookup(1, 1, * + * ... *).first
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

our proto lookup (|) { * }

#| Look up a sequence by its OEIS ID, e.g. 123 for "A000123".
multi lookup (Int $ID) {
    lookup'paginated qq<https://oeis.org/search?q=id:{ $ID.fmt("A%06d") }&fmt=text>
}

#| Look up the sequence from a Seq producing it.
multi lookup (Seq $seq) {
    # TODO: Adaptive
    my @partial-seq = $seq[^8];
    lookup @partial-seq
}

#| Look up a sequence from some of its members.
multi lookup (*@partial-seq) {
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
