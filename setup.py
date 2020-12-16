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

from distutils.sysconfig import get_python_inc
from distutils.dir_util import copy_tree
from shlex import split
from subprocess import call
from sys import platform

from Cython.Distutils import build_ext
from Cython.Distutils.extension import Extension
from setuptools import setup
from meta import VERSION


def check_output(*popenargs, **kwargs):
    return subprocess.check_output(*popenargs, **kwargs).decode("utf-8")


if platform == "linux" or platform == "linux2":
    perl_lib_names = ["Proxy.so"]
elif platform == "darwin":
    perl_lib_names = ["Proxy.bundle", "Proxy.bs"]
elif platform == "win32":
    perl_lib_names = ["Proxy.dll"]
else:
    perl_lib_names = ["Proxy.so"]

PERL_PACKAGE = "PyPerl5"
PERL_LIB_DIR = os.path.join("perl", "lib")
PERL_PACKAGE_DIR = os.path.join(PERL_LIB_DIR, PERL_PACKAGE)

###
perl_compile_args = split(check_output("perl -MExtUtils::Embed -e ccopts".split(" ")).strip())
perl_link_args = split(check_output("perl -MExtUtils::Embed -e ldopts".split(" ")).strip())

perl_compile_args += ("-Wall",)
perl_link_args += ()

ext_modules = [
    Extension(
        "perl5._lib._perl",
        sources=["src/perl5module.pyx", "src/perl5util.c"],
        depends=["src/type_convert.pyx", "src/perl5.pxd", "src/dlfcn.pxd"],
        language="c++",
        extra_compile_args=perl_compile_args,
        extra_link_args=perl_link_args,
        cython_directives={"language_level": sys.version_info.major}
    )
]


def all_files(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            yield os.path.join(root, file)


class Build(build_ext, object):
    perl_installed_files = []

    def run(self):
        os.environ["PYTHON_INC_DIR"] = get_python_inc()
        os.environ["PY_PERL5_VERSION"] = VERSION
        call(["perl", "-MDevel::PPPort", "-e", "Devel::PPPort::WriteFile('src/ppport.h')"])

        # cythonize
        ret = super(Build, self).run()
        os.chdir("perl")
        # if not os.path.exists("Makefile"):
        call(["perl", "Makefile.PL"])
        call(["make"])
        os.chdir("..")

        # copy perl libs into package dir
        targets = [
            (os.path.join("perl", "blib", "lib"), os.path.join(self.build_lib, "perl5", "vendor_perl")),
            (os.path.join("perl", "blib", "arch"), os.path.join(self.build_lib, "perl5", "vendor_perl")),
        ]

        self.perl_installed_files = []

        for src, dst in targets:
            copy_tree(src, dst)
            self.perl_installed_files.extend(all_files(dst))

        return ret

    def get_outputs(self):
        outputs = super(Build, self).get_outputs()  # type: list[str]
        outputs.extend(self.perl_installed_files)
        return outputs


if __name__ == "__main__":
    setup(
        ext_modules=ext_modules,
        cmdclass={"build_ext": Build},
    )
