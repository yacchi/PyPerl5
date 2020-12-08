# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest
from sys import maxint

import perl5
import perl5.vm

minint = -maxint - 1

SCRIPT = r"""
sub method {
    return @_;
}
"""


class TestBasicTypes(unittest.TestCase):
    vm = None

    def setUp(self):
        self.vm = vm = perl5.VM()
        vm.eval(SCRIPT)

    def tearDown(self):
        self.vm.close()

    def call(self, *args, **kwargs):
        return self.vm.call("method", *args, **kwargs)

    # Tests

    def test_None(self):
        self.assertIsNone(None)

    def test_String(self):
        bytes_string = b"Test Bytes"
        self.assertEqual(self.call(bytes_string), bytes_string)

        unicode_string = u"Test Unicode"
        self.assertEqual(self.call(unicode_string), unicode_string)

    def test_Integer(self):

        for n in (0, 1, -1, -2147483647, 2147483646):
            self.assertEqual(self.call(n), n)

        for n in (minint, maxint):
            self.assertEqual(self.call(n), n)

    def test_Float(self):
        for n in (0.0, 1.0):
            self.assertEqual(self.call(n), n)

    def test_Boolean(self):
        for b in (True, False):
            self.assertEqual(self.call(b), b)

    def test_Complex(self):
        for c in (0 + 0j, 1 + 1j):
            self.assertEqual(self.call(c), c)


class TestContainerTypes(unittest.TestCase):
    vm = None

    def setUp(self):
        self.vm = vm = perl5.VM()
        vm.eval(SCRIPT)

    def tearDown(self):
        self.vm.close()

    def call(self, *args, **kwargs):
        return self.vm.call("method", *args, **kwargs)

    # Tests
    dict_dataset = {
        "None": None,
        "Str": "String",
        "Int": 1,
        "Long": 2147483647L,
        "Float": 0.1,
        "Boolean": True,
        "Complex": 1 + 1j
    }

    def test_List(self):
        d = [1]
        self.assertEqual(self.call(d), d)

        d = [1, 2, 3]
        self.assertEqual(self.call(d), d)

        d = [self.dict_dataset]
        self.assertEqual(self.call(d), d)

    def test_Tuple(self):
        d = (1,)
        ret = self.call(d)
        self.assertItemsEqual(d, ret)

        d = (1, 2, 3)
        ret = self.call(d)
        self.assertItemsEqual(d, ret)

        d = (self.dict_dataset,)
        self.assertItemsEqual(self.call(d), d)

    def test_Dict(self):
        d = self.dict_dataset
        self.assertItemsEqual(self.call(d), d)


if __name__ == '__main__':
    unittest.main()
