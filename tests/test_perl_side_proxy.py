# -*- coding:utf8 -*-
from __future__ import division, print_function, unicode_literals

import unittest

import perl5


class ProxyTestObject(object):
    def __init__(self, attr1):
        self._attr1 = attr1

    def attr1(self, data=None):
        if data is None:
            return self._attr1
        self._attr1 = data


def proxy_test_func(arg):
    return arg


SCRIPT = r"""
use PyPerl5::Proxy qw/ py_get_object /;
use PyPerl5::Boolean qw/ true false /;
sub unit_test {
    my $ut = shift;
    
    $ut->assertTrue(1);
    $ut->assertFalse(0);
    
    $ut->assertTrue(true);
    $ut->assertFalse(false);
    
    $ut->assertEqual([1, true], [1, true]);
}

sub unit_test2 {
    my $ut = shift;
    my $class = py_get_object("tests.test_perl_side_proxy.ProxyTestObject");
    $ut->assertTrue($class->isa("PyPerl5::Proxy"));
    
    my $o = $class->new("TEST");
    $ut->assertEqual("TEST", $o->attr1);
    $o->attr1("TEST2");
    $ut->assertEqual("TEST2", $o->attr1);
}

sub unit_test3 {
    my $ut = shift;
    my $f = py_get_object("tests.test_perl_side_proxy.proxy_test_func");
    my $ret = $f->("call");
    $ut->assertEqual("call", $ret); 
}
"""


class TestCase(unittest.TestCase):
    vm = None

    def setUp(self):
        self.vm = vm = perl5.VM()
        vm.eval(SCRIPT)

    def tearDown(self):
        self.vm.close()

    def test_object_proxy(self):
        self.vm.call("unit_test", self)

    def test_py_get_object(self):
        self.vm.call("unit_test2", self)

    def test_function_exec(self):
        self.vm.call("unit_test3", self)


if __name__ == '__main__':
    unittest.main()
