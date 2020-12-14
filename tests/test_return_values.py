# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest

import perl5
import perl5.vm

SCRIPT = r"""
sub no_return {
}

sub method {
    return @_;
}
"""


class TestReturnValues(unittest.TestCase):
    vm = None

    def setUp(self):
        self.vm = vm = perl5.VM()
        vm.eval(SCRIPT)

    def tearDown(self):
        self.vm.close()

    def call(self, *args, **kwargs):
        return self.vm.call("method", *args, **kwargs)

    # Tests
    def test_no_return(self):
        ret = self.vm.call("no_return", 1)
        self.assertEqual(ret, None)

    def test_single_return(self):
        ret = self.call(1)
        self.assertEqual(ret, 1)

    def test_multi_return(self):
        ret = self.call(1, 2)
        self.assertEqual(ret, (1, 2))
        self.assertIsInstance(ret, tuple)

        d = (1, 2, {"3": 4}, [5])
        ret = self.call(*d)
        self.assertEqual(ret, d)
        self.assertIsInstance(ret, tuple)

    def test_code_ref_return(self):
        sub_ref = self.vm.eval("sub {@_}")

        self.assertIsInstance(sub_ref, perl5.vm.CodeRefProxy)
        self.assertEqual(sub_ref(1), 1)
        self.assertEqual(sub_ref("str"), "str")


if __name__ == '__main__':
    unittest.main()
