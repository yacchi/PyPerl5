# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest

import perl5
import perl5.vm
from perl5.vm import VM, Proxy, TypeMapper, CodeRefProxy

SCRIPT = """
package Px::Testing;

sub new {
    my $cls = shift;
    return bless {}, $cls;
}

sub method {
    my $self = shift;
    return @_;
}
1;
"""


class TestCase(unittest.TestCase):

    def test_type(self):
        vm = perl5.VM()

        self.assertIsInstance(vm, VM)
        self.assertIsInstance(vm.type_mapper, TypeMapper)

    def test_object(self):
        vm = perl5.VM()

        ret = vm.eval(SCRIPT)
        self.assertEqual(ret, 1)

        o = vm.package("Px::Testing").new()
        self.assertIsInstance(o, Proxy)

        o2 = vm.package("Px::Testing").new()
        self.assertNotEqual(o, o2)

        method = o.method
        self.assertIsInstance(method, CodeRefProxy)

        self.assertEqual(method, o.method)

        ret = method(1)
        self.assertEqual(ret, 1)


if __name__ == '__main__':
    unittest.main()
