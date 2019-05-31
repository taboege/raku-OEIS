=begin pod

=head1 NAME

X::OEIS - Errors from the OEIS module

=head1 SYNOPSIS

=begin code
use OEIS;
use X::OEIS;

sub count-suggestions (\seq) {
    return OEIS::lookup(\seq, :all).elems;

    CATCH {
        when X::OEIS::TooMany {
            fail "Sorry, query was too general"
        }
    }
}
=end code

=head1 DESCRIPTION

There are four sources of exceptions in OEIS:

=defn Network errors
C<OEIS> uses the WWW module to post queries and download results.
We leave errors below the application level to that module.

=defn Query error
When the OEIS can't understand a query, an exception of type
L<X::OEIS::Query> is thrown.

=defn Parser error
When the C<OEIS> module can't parse a response, an exception of type
L<X::OEIS::Parser> is thrown.

=defn "Too many results. Please narrow search."
This error is returned by the OEIS for queries which are too general,
would require too many sequences to be reported. It has a dedicated
exception L<X::OEIS::TooMany>.

=end pod

unit module X::OEIS;

class Query is Exception {
    has $.message;
    has $.reason;

    submethod TWEAK {
        $!message = "Mal-formatted query: $!reason";
    }
}

class Parser is Exception {
    has $.message;
    has $.reason;

    submethod TWEAK {
        $!message = "Mal-formatted response: $!reason";
    }
}

class TooMany is Exception {
    has $.message = "Too many results";
}

=begin pod

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Tobias Boege

This library is free software; you can redistribute it
and/or modify it under the Artistic License 2.0.

=end pod
