# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest

import perl5.vm


class TestCase(unittest.TestCase):

    def test_context_manager(self):
        with perl5.vm.VM() as vm:
            self.assertFalse(vm.closed)

        self.assertTrue(vm.closed)


if __name__ == '__main__':
    unittest.main()
