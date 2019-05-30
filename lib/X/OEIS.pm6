=begin pod

There are four sources of error:

=item Network error: we leave those to WWW,
=item query errors that OEIS will report,
=item parsing errors when we don't understand a response,
=item "no results found", or "too many results found".

TODO

=end pod

unit module X::OEIS;

class TooMany is Exception {
    has $.message = "Too many results";
}

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
