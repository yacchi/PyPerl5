# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest

import perl5

SCRIPT = r"""
use 5.010;
sub fib {
    my $n = shift;
    return $n if $n < 2;
    return fib($n - 1) + fib($n - 2);
}

sub m_fib {
    state @m;
    my $n = shift;
    return $m[$n] if defined $m[$n];
    return $n if $n < 2;
    my $r = m_fib($n - 1) + m_fib($n - 2);
    $m[$n] = $r;
    return $r
}
"""

FIB_RESULT = [
    0,
    1,
    1,
    2,
    3,
    5,
    8,
    13,
    21,
    34,
    55,
    89,
    144,
    233,
    377,
    610,
    987,
    1597,
    2584,
    4181,
    6765,
    10946,
    17711,
    28657,
    46368,
    75025,
    121393,
]


class TestMathFunc(unittest.TestCase):
    vm = None

    def setUp(self):
        self.vm = vm = perl5.VM()
        vm.eval(SCRIPT)

    def tearDown(self):
        self.vm.close()

    def test_fibonacci(self):
        for n in range(0, 27):
            ret = self.vm.call("fib", n)
            self.assertEqual(FIB_RESULT[n], ret)

    def test_fibonacci_with_memoize(self):
        for n in range(0, 27):
            ret = self.vm.call("m_fib", n)
            self.assertEqual(FIB_RESULT[n], ret)


if __name__ == '__main__':
    unittest.main()
