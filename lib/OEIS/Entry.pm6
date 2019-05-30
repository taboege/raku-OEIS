#| An object representing an entry in the OEIS database.
unit class OEIS::Entry;

use OEIS::Keywords;

has $.ID is required;
has $.MID;
has $.NID;
has @.sequence is required;
has $.name is required;
has @.references;
has @.links;
has @.formulas;
has @.crossrefs;
has $.author; # is required only if not 'dead'
has $.start-arg is required;
has $.offset is required;
has @.maple;
has @.mathematica;
has @.programs;
has @.errata;
has @.examples;
has $.keywords is required;
has @.comments;

#| Parse a set of records in OEIS' L<internal format|https://oeis.org/eishelp1.html>.
method parse-oeis ($text --> Seq) {
    my %partial-object;

    sub make-object {
        take OEIS::Entry.new: |%partial-object if %partial-object;
        %partial-object .= new;
    }

    sub add (*%attribs) {
        for %attribs.kv -> $key, $value {
            # The ID is always the first thing we learn about an entry.
            # If we see a new ID, it means the current entry is done.
            make-object if $key eq "ID";

            if $value ~~ Positional {
                %partial-object{$key}.append: $value<>;
            }
            else {
                %partial-object{$key} = $value;
            }
        }
    }

    gather for $text.lines {
        # Don't forget to emit the last entry.
        LAST make-object;

        # A typical line looks like this:
        # %N A002852 Continued fraction for Euler's constant (or Euler-Mascheroni constant) gamma.
        next unless m/
            ^^
            '%' $<key>=<[ISTUNDHFYAOEeptoKC]> \s
            'A' $<ID>=[\d ** 6]
            [ \s <( .+ )> ]?
            $$
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
                add sequence => [$value.split(/\s* ',' \s*/)».Int]
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
        }
    }
}

submethod TWEAK {
    $!keywords = set($!keywords<>);
}

method gist {
    "OEIS $!ID «$!name»"
}
