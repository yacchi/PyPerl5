# PyPerl5

PyPerl5 is a C-API based binding of perl5.

Supported python versions are 2.7 or 3.6 or higher.

## Installation

This package required python and perl development packages.

```shell script
$ pip install py-perl5
```

##  Usage

### Startup Perl VM and execute script

```python
# -*- coding:utf8 -*-
import perl5

script = r"""
use 5.10.0;
use utf8;

sub method {
    my $arg = shift;
    say $arg;
    return "perl method called with $arg";
}
"""


def some_func():
    vm = perl5.VM()
    vm.eval(script)
    ret = vm.call("method", "hello perl")
    print(ret)

    vm.close()
    

def open_vm_use_context_manager():
    with perl5.VM() as vm:
        vm.eval(script)
        ret = vm.call("method", "hello perl")
        print(ret)
```

### Load perl script file or package
```python
# -*- coding:utf8 -*-
import perl5

def call_method_in_external():
    with perl5.VM() as vm:
        vm.require("sample1.pl")
        ret = vm.call("method", "hello perl")
        print(ret)
        
        vm.use("Data::Dumper")
        dumper = vm.eval('sub {print Data::Dumper->Dump([@_])}')  # type: CodeRefProxy
        dumper({"test": 1})
        
        vm.call_method("Data::Dumper", "Dump", [[{"test": 1}]])
```

### Object control

PyPerl5 can control to Perl package through the proxy object.

```python
# -*- coding:utf8 -*-
import perl5
from perl5.vm import Proxy, CodeRefProxy

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

def object_control():
    with perl5.VM() as vm:
        vm.eval(SCRIPT)
    
        # Create new instance
        o = vm.package("Px::Testing").new()
        assert isinstance(o, Proxy)

        # Create other new instance
        o2 = vm.package("Px::Testing").new()
        assert o != o2

        method = o.method
        assert isinstance(method, CodeRefProxy)
        assert method == o.method

        # Method call use code ref proxy
        ret = method(1)
        assert ret == 1
        
        ret = o.method(2)
        assert ret == 2
```

### Python object access from Perl

Also, control to Python object from Perl code through the proxy object too.

```python
import perl5

PROXY_SCRIPT = """
use 5.10.0;
use PyPerl5::Proxy qw/ py_get_object /;
use PyPerl5::Boolean qw/ true false /;

sub use_python_class {
    my $class = py_get_object("__main__.ProxyTestClass");
    say "Proxy object" if $class->isa("PyPerl5::Proxy");

    # Initialize python class and call method    
    my $o = $class->new("Init python class");
    say $o->attr1;
    say $o->attr1("Set data");
    say $o->attr1;
}

sub use_python_func {
    my $f = py_get_object("__main__.proxy_func");
    my $ret = $f->(1, 2);
    say "Result: $ret, equal: ", $ret == true;
    $ret = $f->(true, true);
    say "Result: $ret, equal: ", $ret == true;
}
"""


class ProxyTestClass(object):
    def __init__(self, attr1):
        self._attr1 = attr1

    def attr1(self, data=None):
        if data is None:
            return self._attr1
        self._attr1 = data


def proxy_func(arg1, arg2):
    return arg1 == arg2


def python_func_call():
    with perl5.VM() as vm:
        vm.eval(PROXY_SCRIPT)

        vm.call("use_python_class")

        vm.call("use_python_func")
```

## TypeMapper

PyPerl5 has a customizable type-mapping system.

Default mapping list:

- a large int or long type map to Math::BigInt
- complex type map to Math::Complex
- file object map to IO::File
- datetime map to DateTime or Time::Piece
- Boolean type map to PyPerl5::Boolean


## Detect PyPerl5 environ

If you hope to detect a PyPerl5 environment, so you can use the 'PyPerl5::Util::run_under_python' method.

```python
import perl5

script = r"""
use 5.10.0;
use PyPerl5::Util qw/ run_under_python /;

sub check {
    say "called from python" if run_under_python;
}
"""

def check_python_env():
    with perl5.VM() as vm:
        vm.eval(script)
        vm.call("check")
```