#!perl

use Test::More;

`bin/ncopy`;

cmp_ok($?, '==', 0, "execute ncopy");

done_testing;

