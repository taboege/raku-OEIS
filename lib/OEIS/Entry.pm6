#| An object representing an entry in the OEIS database.
unit class OEIS::Entry;

use OEIS::Keywords;
use X::OEIS;

has IntStr $.ID is required;
has IntStr $.MID;
has IntStr $.NID;
has Int @.sequence is required;
has Str $.name is required;
has @.references;
has @.links;
has @.formulas;
has @.crossrefs;
has Str $.author; # is required only if not 'dead'
has Int $.start-arg is required;
has Int $.offset is required;
has @.maple;
has @.mathematica;
has @.programs;
has @.errata;
has @.examples;
has $.keywords is required;
has @.comments;

#| Parse a record in OEIS' L<internal format|https://oeis.org/eishelp1.html>.
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
