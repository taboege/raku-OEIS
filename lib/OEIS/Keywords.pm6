=begin pod

=head1 NAME

OEIS::Keywords - OEIS keyword constants

=head1 SYNOPSIS

=begin code
use OEIS;

say OEIS::lookup(1, 1, *+* ... *).keywords;
#= set(core easy hear nice nonn)

# Smartmatching is supported.
say OEIS::lookup(1, 1, *+* ... *) ~~ OEIS::easy;
#= True

# Or directly import the names into your package
use OEIS::Keywords;

say OEIS::lookup((1, 1, *+* ... *), :all).grep(* !~~ easy).head;
#= OEIS A290689 «Number of transitive rooted trees with n nodes.»
=end code

=head1 DESCRIPTION

Sequences in the OEIS are tagged with keywords. There are many of them
and they are available by default in the C<OEIS::> package. You can also
import all the names into the current package by loading C<OEIS::Keywords>.

The Keyword constants support smartmatching L<OEIS::Entry> objects.

=end pod

BEGIN {
    =begin pod

    =begin code
    enum OEIS::Keyword «
        :base(1) bref cofr cons core dead dumb dupe
        easy eigen fini frac full hard hear less look
        more mult new nice nonn obsc sign tabf tabl
        uned unkn walk word
        changed
    »;
    =end code

    =end pod

    # Possible keywords in C<OEIS::Entry.keywords>.
    enum OEIS::Keyword «
        :base(1) bref cofr cons core dead dumb dupe
        easy eigen fini frac full hard hear less look
        more mult new nice nonn obsc sign tabf tabl
        uned unkn walk word
        changed
    »;

    # Allow to smartmatch an OEIS::Entry against a keyword.
    # This requires some metamodel patching. This needs to be
    # done at BEGIN time to avoid an STable conflict.

    OEIS::Keyword.^add_multi_method("ACCEPTS",
        # Dynamic lookup for OEIS::Entry because OEIS::Entry already
        # uses this module and we can't use circularly.
        anon method (OEIS::Keyword:D: ::("OEIS::Entry"):D $entry) {
            self ∈ $entry.keywords
        }
    );
    OEIS::Keyword.^compose;
}

=begin pod

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Tobias Boege

This library is free software; you can redistribute it
and/or modify it under the Artistic License 2.0.

=end pod
