=begin pod

=head1 NAME

OEIS::Entry - Object representing a record in the OEIS

=head1 SYNOPSIS

=begin code
use OEIS;

my OEIS::Entry $ent = OEIS::lookup 1, 1, * + * ... *;
say "OEIS entry { .ID } «{ .name }», by { .author }" with $ent;
#= OEIS entry A000045 «Fibonacci numbers: F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1.», by _N. J. A. Sloane_, 1964
=end code

=head1 DESCRIPTION

The C<OEIS::Entry> class is mostly a container for attributes which
hold the data the OEIS associates with the given sequence.

=end pod

# An object representing an entry in the OEIS database.
unit class OEIS::Entry;

use OEIS::Keywords;
use X::OEIS;

=begin pod

=head2 Attributes

=end pod

=begin pod

=head3 ID, MID, NID

    IntStr $.ID is required
    IntStr $.MID
    IntStr $.NID

The unique IDs assigned to the sequences by the OEIS.
The main ID is C<$.ID>, its stringification begins with
an "A" followed by exactly six zero-padded digits.
Being an IntStr, this ID intifies to the numerical ID,
without the leading "A".

The C<$.MID> and C<$.NID> are deprecated IDs from the
book versions of the OEIS.

=end pod
has IntStr $.ID is required;
has IntStr $.MID;
has IntStr $.NID;

=begin pod

=head3 sequence

    Int @.sequence is required

The integers in the sequence, as many as are stored in
the database.

=end pod
has Int @.sequence is required;

=begin pod

=head3 name

    Str $.name is required

The name of the sequence.

=end pod
has Str $.name is required;

=begin pod

=head3 references, links, formulas, crossrefs

    @.references
    @.links
    @.formulas
    @.crossrefs

C<@.references> contain external literature about the sequence
under consideration, C<@.links> contains hyperlinks in the same
vein. C<@.formulas> contains formulas to compute the sequence.
C<@.crossrefs> links to related sequences in the OEIS.

All of these properties are arrays of free-form lines.

=end pod
has @.references;
has @.links;
has @.formulas;
has @.crossrefs;

=begin pod

=head3 author

    Str $.author

The name of the person who originally entered the sequence into
the OEIS.

The OEIS documentation says that this field is required, but it is
apparently not always present on "dead" sequences.

=end pod
has Str $.author; # is required only if not 'dead'

=begin pod

=head3 start-arg, offset

    Int $.start-arg is required
    Int $.offset is required

The C<$.start-arg> is the index that is usually used for the first
number when defining the sequence (some sequences start at argument
0, others at 1, maybe some at 3, …).

C<$.offset> points (1-based index) at the first entry which is
at least 2, except when there is no such entry, in which case this
field is supposed to contain 1.

=end pod
has Int $.start-arg is required;
has Int $.offset is required;

=begin pod

=head3 maple, mathematica, programs

    has @.maple;
    has @.mathematica;
    has @.programs;

These attributes contain program lines that implement the sequence
in Maple, Mathematica or assorted programming languages, respectively.

=end pod
has @.maple;
has @.mathematica;
has @.programs;

=begin pod

=head3 errata, examples, comments

    has @.errata;
    has @.examples;
    has @.comments;

C<@.errata> discloses errors or extensions made to the entry.
C<@.examples> contains illustrative remarks and examples and
C<@.comments> assorted comments.

=end pod
has @.errata;
has @.examples;
has @.comments;

=begin pod

=head3 keywords

    has $.keywords is required

This is a Set of all keywords of the sequence as L<OEIS::Keyword>
constants.

=end pod
has $.keywords is required;

=begin pod

=head2 method parse

=for code
method parse ($record --> OEIS::Entry:D)

Parses a record string and constructs a new C<OEIS::Entry> objects from it.

The given C<$record> string must consist entirely of %-prefixed "tag lines"
in the OEIS L<internal format|https://oeis.org/eishelp1.html>, such as the
ones returned by L<OEIS::chop-records>.

=end pod

# Parse a record in OEIS' L<internal format|https://oeis.org/eishelp1.html>.
method parse ($record --> OEIS::Entry:D) {
    my %partial-object;

    sub add (*%attribs) {
        temp $_ = %partial-object;
        for %attribs.kv -> $key, $value {
            if $value ~~ Positional {
                # Avoid autovivification because we need to preserve
                # the type of $value.
                if .{$key}:exists {
                    .{$key}.append: $value<>;
                }
                else {
                    .{$key} = $value<>;
                }
            }
            else {
                .{$key} = $value;
            }
        }
    }

    gather for $record.lines {
        # Response parsing error?
        die X::OEIS::Parser.new(reason => "unknown line format '$_'")
            unless m/
                ^
                '%' $<key>=. <.ws>
                'A' $<ID>=[\d ** 6]
                [ <.ws> <( .+ )> ]?
                $
            /;

        my $value = $/.Str.trim;
        given $<key> {
            when 'I' {
                add ID => IntStr.new(+$<ID>, "A$<ID>");

                $value ~~ m/ ['M' $<MID>=[\d ** 4]]? \s ['N' $<NID>=[\d ** 4]]? /;
                add MID => IntStr.new(+$<MID>, "M$<MID>") if $<MID>;
                add NID => IntStr.new(+$<NID>, "N$<NID>") if $<NID>;
            }
            when 'S'|'T'|'U' {
                add sequence => [$value.split(/\s* ',' \s*/, :skip-empty)».Int]
            }
            when 'N' { add name       => $value   }
            when 'D' { add references => [$value] }
            when 'H' { add links      => [$value] }
            when 'F' { add formulas   => [$value] }
            when 'Y' { add crossrefs  => [$value] }
            when 'A' { add author     => $value   }
            when 'O' {
                with $value.split(/\s* ',' \s*/) {
                    add start-arg => +.[0];
                    add offset    => +.[1];
                }
            }
            when 'E' { add errata      => [$value] }
            when 'e' { add examples    => [$value] }
            when 'p' { add maple       => [$value] }
            when 't' { add mathematica => [$value] }
            when 'o' { add programs    => [$value] }
            when 'K' {
                add keywords => $value.split(/\s* ',' \s*/).map: {
                    OEIS::Keyword::{$_} // fail "unknown keyword '$_'"
                }
            }
            when 'C' { add comments => [$value] }
            default {
                die X::OEIS::Parser(reason => "unknown tag '$_'");
            }
        }
    }

    OEIS::Entry.new: |%partial-object.Map
}

submethod TWEAK {
    $!keywords = set($!keywords<>);
}

method gist {
    "OEIS $!ID «$!name»"
}

=begin pod

=head1 SEE ALSO

These attributes are also covered in the OEIS documentation for

=defn OEIS Internal Format
L<https://oeis.org/eishelp1.html>

=defn OEIS Beautified Format
L<https://oeis.org/eishelp2.html>

=head1 AUTHOR

Tobias Boege <tobs@taboege.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Tobias Boege

This library is free software; you can redistribute it
and/or modify it under the Artistic License 2.0.

=end pod
