BEGIN {
    #| Possible keywords in C<OEIS::Entry.keywords>.
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
