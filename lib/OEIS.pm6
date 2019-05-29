=begin pod

=head1 NAME

OEIS - Look up sequences on the On-Line Encyclopedia of Integer Sequences®

=head1 SYNOPSIS

=begin code
use OEIS;

say OEIS::lookup(1, 1, * + * ... *).first.name
#= Fibonacci numbers: F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1.
=end code

=head1 DESCRIPTION

This module provides an interface to the L<On-Line Encyclopedia of Integer Sequences® (OEIS®)|https://oeis.org>,
a web database of integer sequences. Stick an array or Seq into the C<OEIS::lookup>
routine and get back a lazy Seq of all search results as instances of C<OEIS::Entry>.

=end pod

unit module OEIS;

use WWW;

use OEIS::Entry;
use OEIS::Keywords;

# https://oeis.org/eishelp1.html
sub parse-page ($text --> Seq) {
    my $last-id;
    my %data;

    gather for $text.lines {
        # %N A002852 Continued fraction for Euler's constant (or Euler-Mascheroni constant) gamma.
        next unless m/^
            '%' $<key>=<[ISTUNDHFYAOEeptoKC]> \s
            'A' $<ID>=[\d ** 6]
            [ \s <( .+ )> ]?
        $/;

        # If the next entry starts, emit the previous one.
        if quietly $last-id ne $<ID> {
            take OEIS::Entry.new: |%data.Map if %data;
            %data .= new;
        }
        # Also emit at the end.
        LAST take OEIS::Entry.new: |%data if %data;

        $last-id = ~$<ID>;

        my $value = $/.Str.trim;
        given $<key> {
            when 'I' {
                %data<ID> = IntStr.new(+$<ID>, "A$<ID>");
                $value ~~ m/ ['M' $<MID>=[\d ** 4]]? \s ['N' $<NID>=[\d ** 4]]? /;
                if $<MID> {
                    %data<MID> = IntStr.new(+$<MID>, "M$<MID>");
                }
                if $<NID> {
                    %data<NID> = IntStr.new(+$<NID>, "N$<NID>");
                }
            }
            when 'S'|'T'|'U' {
                %data<sequence>.append: $value.split(/\s* ',' \s*/)».Int
            }
            when 'N' { %data<name>   = $value            }
            when 'D' { %data<references>.append:  $value }
            when 'H' { %data<links>.append:       $value }
            when 'F' { %data<formulas>.append:    $value }
            when 'Y' { %data<crossrefs>.append:   $value }
            when 'A' { %data<author> = $value            }
            when 'O' {
                with $value.split(/\s* ',' \s*/) {
                    %data<start-arg> = +.[0];
                    %data<offset> = +.[1];
                }
            }
            when 'E' { %data<errors>.append:      $value }
            when 'e' { %data<examples>.append:    $value }
            when 'p' { %data<maple>.append:       $value }
            when 't' { %data<mathematica>.append: $value }
            when 'o' { %data<programs>.append:    $value }
            when 'K' {
                %data<keywords>.append: $value.split(/\s* ',' \s*/).map: {
                    Keyword::{$_} // fail "unknown keyword '$_'"
                }
            }
            when 'C' { %data<comments>.append:    $value }
        }
    }
}

# TODO: Handle "too many results" error.
# TODO: Return Failure if none found.
sub lookup'paginated ($base-url) {
    my $start = 0;
    my $top-id = -Inf;
    gather PAGE: loop {
        # If the $start argument is too big, OEIS will return
        # the last page again and again. Since the results are
        # in "relevance order", we can't use monotonicity.
        # Instead remember the IDs seen on the previous page
        # and stop if entries repeat.
        for parse-page get "$base-url&start=$start" {
            FIRST {
                last PAGE if $top-id == .ID;
                $top-id = .ID;
            }

            $start++;
            take .self;
        }
    }
}

# TODO: Advanced search syntaxes https://oeis.org/hints.html
# TODO: Normally only return the most relevant Entry. Have :all adverb,
# which returns a Seq of entries. Anything in between can be done
# by methods on that :all Seq.
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
