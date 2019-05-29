#| An object representing an entry in the OEIS database.
unit class OEIS::Entry;

has $.ID is required;
has $.MID;
has $.NID;
has @.sequence is required;
has $.name is required;
has @.references;
has @.links;
has @.formulas;
has @.crossrefs; # TODO: make this a lazy Seq fetching the entries.
has $.author is required;
has $.start-arg is required;
has $.offset is required;
has @.maple;
has @.mathematica;
has @.programs;
has @.errors;
has @.examples;
has @.keywords is required;
has @.comments;

method gist {
    "OEIS $!ID «$!name»"
}
