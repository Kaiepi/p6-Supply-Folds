[![Build Status](https://travis-ci.com/Kaiepi/p6-Supply-Folds.svg?branch=master)](https://travis-ci.com/Kaiepi/p6-Supply-Folds)

NAME
====

Supply::Folds - Alternative fold methods for Supply

SYNOPSIS
========

```perl6
# Let's say we want to parse payloads from a TCP connection:
my Supply:D $connection = supply {
    emit 'fo';
    emit 'obarb';
    emit 'azf';
    emit 'ooba';
    emit 'rbazfooba';
    emit 'rbaz';
    done;
};

# It's not guaranteed that these payloads will be complete messages, so our
# parser needs to keep context for where it is in the stream of payloads...
grammar Connection::Grammar {
    token TOP { ( foo | bar | baz )+ }
}
class Connection::Actions {
    method TOP($/) { make $0».Str }
}

# ...but this is a problem! We don't want locks slowing down communication with
# our peer, but we need to hold on to our parser as we parse each payload
# received! Psych, this isn't a problem with Supply.scan:
react whenever $connection.scan: &parse-payload, Connection::Grammar {
    .made.say;
    # OUTPUT:
    # Nil
    # [foo bar]
    # [baz]
    # [foo]
    # [bar baz foo]
    # [bar baz]
}

proto sub parse-payload(Connection::Grammar:_, Str:D --> Connection::Grammar:D) {*}
multi sub parse-payload(Connection::Grammar:U $acc, Str:D $payload --> Connection::Grammar:D) {
    $acc.subparse: $payload, actions => Connection::Actions.new;
}
multi sub parse-payload(Connection::Grammar:D $acc, Str:D $payload --> Connection::Grammar:D) {
    $acc.subparse: $acc.orig.substr(max $acc.pos, 0) ~ $payload, actions => $acc.actions
}
```

DESCRIPTION
===========

Supply::Folds is a library that provides the `Supply.fold` and `Supply.scan` methods, which can be used as an alternative to `Supply.reduce` and `Supply.produce`. The main advantage these methods have over those is that they may optionally take an initial value to begin a fold/scan with, rather than only working using values emitted by the supply.

METHODS
=======

method fold
-----------

```perl6
method fold(::?CLASS:D: &folder is raw --> ::?CLASS:D)
```

Alias for `Supply.reduce`.

```perl6
method fold(::?CLASS:D: &folder is raw, $init is raw --> ::?CLASS:D)
```

Using `$init` as the initial result of the fold, for each value emitted from `self`, call `&folder` with the previous result and the value emitted, setting the result to the return value. This will be emitted once the supply is done.

method scan
-----------

```perl6
method scan(::?CLASS:D: &scanner is raw --> ::?CLASS:D)
```

Alias for `Supply.produce`.

```perl6
method scan(::?CLASS:D: &scanner is raw, $init is raw, Bool:D :$keep = False --> ::?CLASS:D)
```

Using `$init` as the initial result of the scan, for each value emitted from `self`, call `&scanner` with the previous result and the value emitted, setting the result to the return value and emitting it. If `$keep` is set to `True`, `$init` will be emitted before the scan starts.

AUTHOR
======

Ben Davies (Kaiepi)

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

