=begin pod

=head1 NAME

OEIS - Look up sequences on the On-Line Encyclopedia of Integer Sequences®

=head1 SYNOPSIS

=begin code
use OEIS;

say OEIS::lookup 1, 1, * + * ... *;
#= OEIS A000045 «Fibonacci numbers: F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1.»

say OEIS::lookup((1, 1, *+* ... *), :all).grep(* !~~ OEIS::easy).head;
#= OEIS A290689 «Number of transitive rooted trees with n nodes.»

say OEIS::lookup(1, 2, 4 ... ∞).mathematica.head;
#= Table[2^n, {n, 0, 50}]
=end code

=head1 DESCRIPTION

This module provides an interface to the L<On-Line Encyclopedia of Integer Sequences® (OEIS®)|https://oeis.org>,
a web database of integer sequences. Stick an array or Seq into the C<OEIS::lookup>
routine and get back the most relevant result that OEIS finds, as an instance of
L<OEIS::Entry>. With the C<:all> adverb, it returns a lazy Seq of all results.
Sequences can also be looked up by their IDs. See below for details.

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

# Return a lazy Seq for all pages for the given query.
# This already raises errors that can be read off from the header where
# the pagination control information would normally be, including query
# errors and "too many results". If no result was return, the Seq is
# correspondingly empty.
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

=begin pod

=head2 sub fetch

=for code
multi fetch (Int $ID, :$type = 'A')
multi fetch (Str $ID where { … })
multi fetch (Seq $seq)
multi fetch (*@partial-seq)

Searches for a sequence identified by

=item its C<Int $ID> under the C<$type> namespace,
e.g. the Fibonacci numbers are sequence 45 in type C<A>,
692 in type C<M> and 256 in type C<N>,
=item its C<Str $ID> already containing the C<$type>,
again the Fibonacci numbers are "A000045", "M0692" or "N0256",
=item a Seq generating the sequence,
=item an array containing sequence elements

and returns all result pages in OEIS's internal text format
as a lazy Seq.

This is a very low-level method. See L<OEIS::lookup> for a more
convenient interface.

=end pod

our proto fetch (|) { * }

# Look up a sequence by its OEIS ID, e.g. 123 for "A000123".
multi fetch (Int $ID, :$type = 'A') {
    fetch'paginated qq<https://oeis.org/search?q=id:{ $type ~ $ID.fmt("%06d") }&fmt=text>
}

# Look up a sequence by its stringified OEIS ID, e.g. "A000123".
multi fetch (Str $ID where * ~~ /^ $<type>=<[AMN]> <( \d+ )> $/) {
    samewith +$/, :$<type>
}

# Look up the sequence from a Seq producing it.
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

# Look up a sequence from some of its members.
multi fetch (*@partial-seq) {
    fetch'paginated qq<https://oeis.org/search?q={ @partial-seq.join(',') }&fmt=text>
}

=begin pod

=head2 sub chop-records

=for code
multi chop-records (Seq \pages)
multi chop-records (Str $page)

Takes a single page in OEIS' internal format, or a Seq of them
(the return value of L<OEIS::fetch>), and returns a Seq of all
OEIS records contained in them, as multiline strings.

You will only need this sub if you get pages from a source
that isn't L<OEIS::fetch>, e.g. from a cache on disk, or if
you want the textual records instead of L<OEIS::Entry> objects.

More a more convenient interface, see L<OEIS::lookup>.

=end pod

our proto chop-records (|) { * }

# Turn a sequence of pages into a sequence of records.
multi chop-records (Seq \pages) {
    gather for pages -> $page {
        take .self for chop-records($page);
    }
}

# Turn a single page into a sequence of records.
multi chop-records (Str $page) {
    my @record;

    sub emit-record {
        take @record.join("\n") if @record;
        @record .= new;
    }

    # E.g.: %N A002852 Continued fraction for Euler's constant (or Euler-Mascheroni constant) gamma.
    gather for $page.lines.grep(*.starts-with: '%') {
        # Don't forget to emit the last record.
        LAST emit-record;

        emit-record if m/^ '%I' /;
        push @record, $_;
    }
}

=begin pod

=head2 sub lookup

=for code
sub lookup (:$all = False, |c)

This high-level sub calls L<OEIS::fetch> with the captured arguments
C<|c>, followed by L<OEIS::chop-records> and then creates for each
record an L<OEIS::Entry> object. Naturally, all search features of
L<OEIS::fetch> are supported.

By default only the first record is returned. This is the one that
OEIS deems most relevant to the search. If the named argument C<$all>
is True, all records are returned as a lazy Seq.

If no result was found, the Seq is empty. Note that a too general
query leads to "too many results, please narrow search" error from
the OEIS. For other possible errors, see L<X::OEIS>.

=end pod

our sub lookup (:$all = False, |c) {
    my $seq = chop-records fetch |c;
    $seq .= map: { OEIS::Entry.parse($_) };
    $all ?? $seq !! $seq.first
}

=begin pod

=head2 sub lookup-all

=for code
sub lookup-all (|c)

This sub is equivalent to C<lookup(:all, |c)>. It exists because when
you write a Seq directly into the C<lookup> call, the C<:all> adverb
is swallowed into the Seq by the comma operator, unless the Seq is
parenthesized, which you may want to avoid having to do.

=end pod

our sub lookup-all (|c) {
    my \seq = chop-records fetch |c;
    seq.map: { OEIS::Entry.parse($_) }
}

=begin pod

=head1 SEE ALSO

=defn OEIS Internal Format documentation
L<https://oeis.org/eishelp1.html>

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2018/9 Tobias Boege

This library is free software; you can redistribute it
and/or modify it under the Artistic License 2.0.

=end pod
