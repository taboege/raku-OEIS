unit module Test::OEIS;

use Test;

my $offline-skipped;

END {
    diag "skipped $offline-skipped tests requiring NETWORK_TESTING"
        if $offline-skipped;
}

sub online (&block) is export {
    state $online =
        %*ENV<NETWORK_TESTING> //
        %*ENV<ONLINE_TESTING> //
        False;
    state $diag'd;

    if $online {
        block;
    }
    else {
        $offline-skipped++;
        skip 'NETWORK_TESTING not enabled';
    }
}
