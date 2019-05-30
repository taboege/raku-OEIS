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

sub fetch'paginated ($query-url, :$start is copy = 0) {
    gather PAGE: loop {
        my $page = get "$query-url&start=$start";
        for $page.lines {
            # Skip smalltalk
            next if m/^ '#' /;
            next if m/^ \s* $/;
            next if m/^ 'Search:' /;

            # Too many results is an error scenario for OEIS.
            die X::OEIS::TooMany.new
                if m/^ 'Too many results. Please narrow search.' $/;

            # Query parsing error on the server side?
            die X::OEIS::Query.new(reason => $/.trim)
                if m/^ 'Could not parse search query:' <.ws> <( .* )> $/;

            # No results leads to empty Seq
            last PAGE if m/^ 'No results.' $/;

            # Finally the non-exceptional case: what does this page contain?
            # E.g. "Showing 151-153 of 153"
            die X::OEIS::Parser.new(reason => "could not find 'Showing' line in header")
                unless m/
                    ^
                    'Showing'
                    <.ws> (\d+) '-' (\d+) <.ws>
                    'of' <.ws> (\d+)
                    $
                /;

            take $page;
            last PAGE if $1 == $2; # final page?
            # The `start` GET parameter is 0-based but the response
            # shows it 1-based, so this is *not* off-by-one.
            $start = +$1 and next PAGE;
        }
    }
}

our proto fetch (|) { * }

#| Look up a sequence by its OEIS ID, e.g. 123 for "A000123".
multi fetch (Int $ID, :$type = 'A') {
    fetch'paginated qq<https://oeis.org/search?q=id:{ $type ~ $ID.fmt("%06d") }&fmt=text>
}

#| Look up a sequence by its stringified OEIS ID, e.g. "A000123".
multi fetch (Str $ID where * ~~ /^ $<type>=<[AMN]> <( \d+ )> $/) {
    samewith +$/, :$<type>
}

#| Look up the sequence from a Seq producing it.
multi fetch (Seq $seq) {
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
multi fetch (*@partial-seq) {
    fetch'paginated qq<https://oeis.org/search?q={ @partial-seq.join(',') }&fmt=text>
}

#| Turn a sequence of pages into a sequence of records.
sub chop-records (\pages) {
    gather for pages {
        state @record;

        sub emit-record {
            take @record.join("\n") if @record;
            @record .= new;
        }

        # Don't forget to emit the last record.
        LAST emit-record;

        # %N A002852 Continued fraction for Euler's constant (or Euler-Mascheroni constant) gamma.
        for .lines.grep(*.starts-with: '%') {
            emit-record if m/^ '%I' /;
            push @record, $_;
        }
    }
}

our sub lookup (:$all = False, |c) {
    my $seq = chop-records fetch |c;
    $seq .= map: { OEIS::Entry.parse($_) };
    $all ?? $seq !! $seq.first
}

=begin pod

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2018/9 Tobias Boege

This library is free software; you can redistribute it
and/or modify it under the Artistic License 2.0.

=end pod
