NAME
====

OEIS - Look up sequences on the On-Line Encyclopedia of Integer Sequences®

SYNOPSIS
========

``` perl6
use OEIS;

say OEIS::lookup(1, 1, * + * ... *).first.name
#= Fibonacci numbers: F(n) = F(n-1) + F(n-2) with F(0) = 0 and F(1) = 1.
```

DESCRIPTION
===========

This module provides an interface to the [On-Line Encyclopedia of Integer Sequences® (OEIS®)](https://oeis.org),
a web database of integer sequences. Stick an array or Seq into the `OEIS::lookup`
routine and get back a lazy Seq of all search results as instances of `OEIS::Entry`.

AUTHOR
======

Tobias Boege <tboege ☂ ovgu ☇ de>

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Tobias Boege

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
