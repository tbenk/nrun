#!perl

use Test::More;

`bin/nrun -c ls localhost`;

cmp_ok($?, '==', 0, "execute nrun");

done_testing;

