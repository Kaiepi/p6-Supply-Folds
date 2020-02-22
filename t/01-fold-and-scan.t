use v6.d;
use Supply::Folds;
use Test;

plan 3;

subtest 'Supply.fold', {
    plan 2;

    cmp-ok supply for 1..3 { .emit }.fold(&infix:<+>).&await, &[===], 6,
      'can fold supplies';
    cmp-ok supply for 1..3 { .emit }.fold(&infix:<*>, 1).&await, &[===], 6,
      'can fold supplies with an initial value';
};

subtest 'Supply.scan', {
    plan 3;

    cmp-ok @(supply for 1..3 { .emit }.scan(&infix:<+>)), &[eqv], (1, 3, 6),
      'can scan supplies';
    cmp-ok @(supply for 1..3 { .emit }.scan(&infix:<*>, 1)), &[eqv], (1, 2, 6),
      'can scan supplies with an initial value';
    cmp-ok @(supply for 2..3 { .emit }.scan(&infix:<*>, 1, :keep)), &[eqv], (1, 2, 6),
      'can scan supplies with an initial value and keep it';
};

subtest 'synopsis', {
    plan 1;

    my Supply:D $connection = supply {
        emit 'fo';
        emit 'obarb';
        emit 'azf';
        emit 'ooba';
        emit 'rbazfooba';
        emit 'rbaz';
        done;
    };

    my grammar Connection::Grammar {
        token TOP { ( foo | bar | baz )+ }
    }
    my class Connection::Actions {
        method TOP($/) { make $0».Str }
    }

    proto sub parse-payload(Connection::Grammar:_, Str:D --> Connection::Grammar:D) {*}
    multi sub parse-payload(Connection::Grammar:U $acc, Str:D $payload --> Connection::Grammar:D) {
        $acc.subparse: $payload, actions => Connection::Actions.new;
    }
    multi sub parse-payload(Connection::Grammar:D $acc, Str:D $payload --> Connection::Grammar:D) {
        $acc.subparse: $acc.orig.substr(max $acc.pos, 0) ~ $payload, actions => $acc.actions
    }

    my Channel:D $values .= new;
    react whenever $connection.scan: &parse-payload, Connection::Grammar {
        $values.send: .made;
        LAST {
            $values.close;
            done;
        }
    }
    cmp-ok @$values, &[eqv], (Nil, ['foo', 'bar'], ['baz'], ['foo'], ['bar', 'baz', 'foo'], ['bar', 'baz']),
      'the code from the synopsis runs OK';
};

# vim: ft=perl6 sw=4 ts=4 sts=4 et
