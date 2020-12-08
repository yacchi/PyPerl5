# -*- coding: utf-8 -*-
from __future__ import print_function

try:
    import setuptools.monkey
    setuptools.monkey.patch_all()
except ImportError:
    import setuptools
    import distutils.core
    import distutils.extension

    distutils.core.Extension = setuptools.Extension
    distutils.extension.Extension = setuptools.Extension

import os
import subprocess
import sys
from distutils.command.build import build
from distutils.sysconfig import get_python_inc
from shlex import split
from subprocess import call
from sys import platform

from Cython.Distutils import build_ext
from Cython.Distutils.extension import Extension
from setuptools import setup


def check_output(*popenargs, **kwargs):
    return subprocess.check_output(*popenargs, **kwargs).decode("utf-8")


os.environ["PYTHON_INC_DIR"] = get_python_inc()

if platform == "linux" or platform == "linux2":
    perl_lib_name = "Proxy.so"
elif platform == "darwin":
    perl_lib_name = "Proxy.bundle"
elif platform == "win32":
    perl_lib_name = "Proxy.dll"
else:
    perl_lib_name = "Proxy.so"

sys.path.insert(0, "lib")
# sys.path.insert(0, "build/lib.linux-x86_64-2.7")
# sys.path.insert(0, "build/lib.macosx-10.12-x86_64-2.7")

version = "1.0"

PERL_PACKAGE = "PyPerl5"
PERL_LIB_DIR = os.path.join("perl", "lib")
PERL_PACKAGE_DIR = os.path.join(PERL_LIB_DIR, PERL_PACKAGE)

os.environ["PERL5LIB"] = ":".join(
    [os.path.join(os.path.abspath(os.curdir), p) for p in (PERL_LIB_DIR, 'perl/blib/arch')])

###
perl_compile_args = split(check_output("perl -MExtUtils::Embed -e ccopts".split(" ")).strip())
perl_link_args = split(check_output("perl -MExtUtils::Embed -e ldopts".split(" ")).strip())
perl_lib_dir = check_output(["perl", "-MConfig", "-E", 'say $Config{vendorlib}']).strip()
perl_xs_lib_dir = check_output(["perl", "-MConfig", "-E", 'say $Config{vendorarchexp}']).strip()

perl_compile_args += ("-Wall",)
perl_link_args += ()

ext_modules = [
    Extension(
        "_perl5",
        sources=["src/perl5module.pyx", "src/perl5util.c"],
        depends=["src/type_convert.pyx", "src/perl5.pxd", "src/dlfcn.pxd"],
        language="c++",
        extra_compile_args=perl_compile_args,
        extra_link_args=perl_link_args,
        cython_directives={"language_level": sys.version_info.major}
    )
]

data_files = [
    (os.path.join(perl_lib_dir, PERL_PACKAGE),
     (os.path.join(PERL_PACKAGE_DIR, p) for p in os.listdir(PERL_PACKAGE_DIR))),
    (os.path.join(perl_xs_lib_dir, 'auto/PyPerl5/Proxy'),
     (os.path.join("perl/blib/arch/auto/PyPerl5/Proxy/", perl_lib_name),)),
]


class Build(build):
    def run(self):
        call(["perl", "-MDevel::PPPort", "-e", "Devel::PPPort::WriteFile('src/ppport.h')"])
        ret = build.run(self)

        os.chdir("perl")
        if not os.path.exists("Makefile"):
            call(["perl", "Makefile.PL"])
        call(["make"])
        os.chdir("..")
        return ret


with open("README.rst") as f:
    readme = f.read()

if __name__ == "__main__":
    setup(
        name="PyPerl5",
        author="Yasunori Fujie",
        author_email="fuji@dmgw.net",
        version=version,
        packages=["perl5"],
        description="Perl 5 integration for python",
        long_description=readme,
        url='https://github.com/yacchi21/PyPerl5',
        license='Apache License, Version 2.0',
        ext_modules=ext_modules,
        data_files=data_files,
        cmdclass={"build_ext": build_ext, "build": Build},
        test_suite="test.test_suite",
    )
