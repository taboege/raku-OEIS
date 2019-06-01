NAME
====

OEIS - Look up sequences on the On-Line Encyclopedia of Integer Sequences®

SYNOPSIS
========

``` perl6
use OEIS;

say OEIS::lookup 1, 1, * + * ... *;
#= OEIS A000045 «Fibonacci numbers: F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1.»

say OEIS::lookup(1, 2, 4 ... ∞).mathematica.head;
#= Table[2^n, {n, 0, 50}]

# Notice that only some terms of the Seq are evaluated!
with OEIS::lookup-all(1, 1, * + * ... *).grep(* !~~ OEIS::easy).head {
    say .gist;     #= OEIS A290689 «Number of transitive rooted trees with n nodes.»
    say .sequence; #= [1 1 1 2 3 5 8 13 21 34 55 88 143 229 370 592 955 1527 2457 3929]
}
```

DESCRIPTION
===========

This module provides an interface to the [On-Line Encyclopedia of Integer Sequences® (OEIS®)](https://oeis.org), a web database of integer sequences. Stick an array or Seq into the `OEIS::lookup` routine and get back the most relevant result that OEIS finds, as an instance of [OEIS::Entry](OEIS::Entry). With the `:all` adverb, it returns a lazy Seq of all results. Sequences can also be looked up by their IDs. See below for details.

sub fetch
---------

``` perl6
multi fetch (Int $ID, :$type = 'A')
multi fetch (Str $ID where { … })
multi fetch (Seq $seq)
multi fetch (*@partial-seq)
```

Searches for a sequence identified by

  * its `Int $ID` under the `$type` namespace, e.g. the Fibonacci numbers are sequence 45 in type `A`, 692 in type `M` and 256 in type `N`,

  * its `Str $ID` already containing the `$type`, again the Fibonacci numbers are "A000045", "M0692" or "N0256",

  * a Seq generating the sequence,

  * an array containing sequence elements

and returns all result pages in OEIS's internal text format as a lazy Seq.

This is a very low-level method. See [OEIS::lookup](OEIS::lookup) for a more convenient interface.

sub chop-records
----------------

``` perl6
multi chop-records (Seq \pages)
multi chop-records (Str $page)
```

Takes a single page in OEIS' internal format, or a Seq of them (the return value of [OEIS::fetch](OEIS::fetch)), and returns a Seq of all OEIS records contained in them, as multiline strings.

You will only need this sub if you get pages from a source that isn't [OEIS::fetch](OEIS::fetch), e.g. from a cache on disk, or if you want the textual records instead of [OEIS::Entry](OEIS::Entry) objects.

More a more convenient interface, see [OEIS::lookup](OEIS::lookup).

sub lookup
----------

``` perl6
sub lookup (:$all = False, |c)
```

This high-level sub calls [OEIS::fetch](OEIS::fetch) with the captured arguments `|c`, followed by [OEIS::chop-records](OEIS::chop-records) and then creates for each record an [OEIS::Entry](OEIS::Entry) object. Naturally, all search features of [OEIS::fetch](OEIS::fetch) are supported.

By default only the first record is returned. This is the one that OEIS deems most relevant to the search. If the named argument `$all` is True, all records are returned as a lazy Seq.

If no result was found, the Seq is empty. Note that a too general query leads to "too many results, please narrow search" error from the OEIS. For other possible errors, see [X::OEIS](X::OEIS).

sub lookup-all
--------------

``` perl6
sub lookup-all (|c)
```

This sub is equivalent to `lookup(:all, |c)`. It exists because when you write a Seq directly into the `lookup` call, the `:all` adverb is swallowed into the Seq by the comma operator, unless the Seq is parenthesized, which you may want to avoid having to do.

SEE ALSO
========

- [OEIS Internal Format documentation](https://oeis.org/eishelp1.html)

AUTHOR
======

Tobias Boege <tobs@taboege.de>

COPYRIGHT AND LICENSE
=====================

Copyright 2018/9 Tobias Boege

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

