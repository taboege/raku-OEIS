unit module Test::OEIS;

use Test;

sub online (&block) is export {
    state $online =
        %*ENV<NETWORK_TESTING> //
        %*ENV<ONLINE_TESTING> //
        False;

    if $online {
        block;
    }
    else {
        skip 'NETWORK_TESTING not enabled';
    }
}
