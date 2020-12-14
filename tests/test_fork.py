# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest
from signal import SIGINT, SIG_IGN

import os

import perl5

SCRIPT = r"""
sub pure_fork {
    my $pid = fork;
    if (!$pid) {
        sleep(10);
        exit(0);
    }
    
    return $pid;
}
"""


class TestCase(unittest.TestCase):
    vm = None

    def setUp(self):
        self.vm = vm = perl5.VM()
        vm.eval(SCRIPT)

    def tearDown(self):
        self.vm.close()

    def test_fork(self):
        pid = self.vm.call("pure_fork")
        self.assertIsInstance(pid, int)

        try:
            os.kill(pid, SIG_IGN)
        except OSError:
            assert True

        os.kill(pid, SIGINT)
        exit_pid, exit_status = os.waitpid(pid, 0)

        self.assertEqual(pid, exit_pid)
        self.assertEqual(0, 0)

        with self.assertRaises(OSError) as cm:
            os.kill(pid, SIG_IGN)

        self.assertIsInstance(cm.exception, OSError)


if __name__ == '__main__':
    unittest.main()
