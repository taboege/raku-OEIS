unit module Test::OEIS;

use Test;

sub online (&block) is export {
    state $online =
        %*ENV<NETWORK_TESTING> //
        %*ENV<ONLINE_TESTING> //
        False;
    state $diagged;

    if $online {
        block;
    }
    else {
        $diagged //= diag 'skipping tests without NETWORK_TESTING';
        skip 'NETWORK_TESTING not enabled';
    }
}
