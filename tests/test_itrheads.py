# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest

import perl5

SCRIPT = r"""
use threads;

sub thread_func {
    return 1;
}
sub thread_test {
    my $num_of_threads = shift;
    my @ths;
    
    for my $n (1..$num_of_threads) {
        my $th = threads->create(\&thread_func);
        push @ths, $th;
    }
    
    my $ret = 0;
    for my $th (@ths) {
        $ret += $th->join;
    }
    return $ret;
}
"""


class TestCase(unittest.TestCase):
    vm = None

    def setUp(self):
        self.vm = vm = perl5.VM()
        vm.eval(SCRIPT)

    def tearDown(self):
        self.vm.close()

    def test_thread(self):
        ret = self.vm.call("thread_test", 10)
        self.assertEqual(ret, 10)


if __name__ == '__main__':
    unittest.main()
