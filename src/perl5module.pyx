# -*- coding: utf-8 -*-
from __future__ import absolute_import

cdef extern from "config.h":
    cdef char* VERSION
    cdef char* PERL5SV_CAPSULE_NAME

cimport dlfcn
# unsupported relative cimport in old cython on centos7
# noinspection PyUnresolvedReferences,PyProtectedMember
cimport perl5

from cpython cimport *
from cpython.version cimport PY_MAJOR_VERSION
from libcpp.vector cimport vector

import os
from io import IOBase
from threading import RLock

__version__ = VERSION

if PY_MAJOR_VERSION < 3:
    # noinspection PyUnresolvedReferences
    basestring = __builtins__.basestring
else:
    basestring = (bytes, str)
    unicode = str
    long = int

cdef void *libperl

cdef extern from "<Python.h>":
    void Py_AtExit(void (*func)()) nogil
    object PyUnicode_FromStringAndSize(char*, Py_ssize_t)
    object PyObject_check(object)
    Py_ssize_t Py_REFCNT(object)


cdef char* PyBaseString_AsString(s):
    if PyBytes_Check(s):
        return PyBytes_AS_STRING(s)
    if PyUnicode_Check(s):
        return PyBytes_AS_STRING(PyUnicode_AsUTF8String(s))
    raise TypeError("unsupported non basestring type of " + str(s) + " " + str(type(s)))


cdef char** to_cstring_array(list_of_str):
    cdef Py_ssize_t size = len(list_of_str), i
    cdef char ** ret = <char**> PyMem_Malloc(size * sizeof(char*))
    if not ret:
        raise MemoryError("can not allocate memory")

    for i in range(size):
        ret[i] = PyBaseString_AsString(list_of_str[i])
    return ret


cdef int __put_stack(Context ctx, object obj, vector[perl5.SV*]& arg_stack) except -1:
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef:
        perl5.SV *sv_key
        perl5.SV *sv_value

    if isinstance(obj, BaseProxy):
        sv_value = get_sv_from_capsule(obj.perl_capped_sv)
        arg_stack.push_back(sv_value)

    elif isinstance(obj, dict):
        for k, v in obj.items():
            sv_key = PyObject2PerlSV(ctx, k)
            sv_value = PyObject2PerlSV(ctx, v)

            arg_stack.push_back(perl5.sv_2mortal(sv_key))
            arg_stack.push_back(perl5.sv_2mortal(sv_value))

    elif isinstance(obj, (list, tuple)):
        for v in obj:
            sv_value = PyObject2PerlSV(ctx, v)
            arg_stack.push_back(perl5.sv_2mortal(sv_value))

    else:
        sv_value = PyObject2PerlSV(ctx, obj)
        arg_stack.push_back(perl5.sv_2mortal(sv_value))

    return 1

cdef inline int __perl_call(Context ctx, object package_or_proxy, object subroutine):
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef perl5.SV *sv
    cdef char *c_subroutine_name
    cdef perl5.I32 flag = perl5.G_ARRAY | perl5.G_EVAL

    if package_or_proxy is not None:
        c_subroutine_name = PyBaseString_AsString(subroutine)
        with nogil:
            num_of_args = perl5.call_method(c_subroutine_name, flag)

    else:
        sv = PyObject2PerlSV(ctx, subroutine)

        if ctx.noargs:
            flag |= perl5.G_NOARGS

        with nogil:
            num_of_args = perl5.call_sv(sv, flag)
            perl5.SvREFCNT_dec(sv)

    return num_of_args

cdef inline void __perl_error_check(Context ctx) except *:
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef perl5.STRLEN n_a
    cdef char *error

    if perl5.SvTRUE(perl5.PERL5_MODULE_ERRSV()):
        # print(ctx.invocant, ctx.subroutine, ctx.arguments)
        raise PerlRuntimeError(perl5.SvPV(perl5.PERL5_MODULE_ERRSV(), n_a))


class PerlRuntimeError(RuntimeError):
    pass


cdef void PerlSVDestroy(object obj):
    perl5.INIT_MY_PERL()
    cdef perl5.SV *sv = NULL

    ctx = PyCapsule_GetContext(obj)
    if ctx == NULL:
        return

    vm = <VM> ctx
    if vm.closed or vm.my_perl == NULL:
        return

    perl5.SET_MY_PERL(vm.my_perl)

    sv = <perl5.SV*> PyCapsule_GetPointer(obj, PERL5SV_CAPSULE_NAME)
    perl5.SvREFCNT_dec(sv)

cdef inline object make_perl_sv_capsule(VM context, perl5.SV *sv):
    perl5.SvREFCNT_inc(sv)
    capsule = PyCapsule_New(<void*> sv, PERL5SV_CAPSULE_NAME, PerlSVDestroy)
    PyCapsule_SetContext(capsule, <void*> context)
    return capsule

cdef inline perl5.SV*get_sv_from_capsule(object obj) except NULL:
    cdef perl5.SV*sv

    sv = <perl5.SV*> PyCapsule_GetPointer(obj, PERL5SV_CAPSULE_NAME)
    if sv == NULL:
        raise PerlRuntimeError("can not get SV pointer")
    return sv

ctypedef api class Context[object PyPerl5Context, type PyPerl5ContextType]:
    cdef:
        readonly VM vm
        readonly object invocant
        readonly object subroutine
        # perl5.PerlInterpreter *my_perl
        readonly object arguments
        readonly int noargs

    def __cinit__(self, VM vm, invocant=None, subroutine=None, arguments=None, *args, **kwargs):
        self.vm = vm
        self.invocant = invocant
        self.subroutine = subroutine
        self.arguments = arguments

        noargs = 1 if not arguments else 0
        self.noargs = noargs

    def __init__(self, vm, invocant=None, subroutine=None, arguments=None, *args, **kwargs):
        pass

    def package(self):
        if self.invocant:
            return self.invocant.__perl_package__

include "type_convert.pyx"

cdef class BaseProxy:
    cdef readonly Context _context
    cdef readonly VM _vm
    cdef readonly object perl_capped_sv
    cdef readonly object __perl_package__

    def __cinit__(self, Context ctx, object capped_sv, *args, **kwargs):
        self._vm = ctx.vm
        self._context = ctx
        self.perl_capped_sv = capped_sv

    def __init__(self, Context ctx, object capped_sv, *args, **kwargs):
        pass

    def sv_dump(self):
        perl5.INIT_SET_MY_PERL(self._vm.my_perl)
        cdef perl5.SV *sv = get_sv_from_capsule(self.perl_capped_sv)
        perl5.sv_dump(sv)

    def __repr__(self):
        return "{0}.{1}({2}) at 0x{3:x}".format(
            self.__class__.__module__, self.__class__.__name__,
            self.__perl_package__, id(self))

    def __richcmp__(self, other, operation):
        cdef:
            perl5.SV *sv_a
            perl5.SV *sv_b

        if operation == 2 or operation == 3:  # ==
            if isinstance(other, BaseProxy):
                sv_a = get_sv_from_capsule(self.perl_capped_sv)
                sv_b = get_sv_from_capsule(other.perl_capped_sv)
                if perl5.SvROK(sv_a):
                    sv_a = perl5.SvRV(sv_a)
                if perl5.SvROK(sv_b):
                    sv_b = perl5.SvRV(sv_b)
                return (sv_a == sv_b) ^ (operation == 3)
            return False ^ (operation == 3)
        raise NotImplementedError

    def __dealloc__(self):
        self.perl_capped_sv = None
        self.__perl_package__ = None

cdef class Proxy(BaseProxy):
    cdef public dict __perl_members__

    def __cinit__(self, Context ctx, object capped_sv, *args, **kwargs):
        perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)
        cdef:
            perl5.SV *rv
            perl5.SV *sv

        if PyCapsule_CheckExact(capped_sv):
            rv = get_sv_from_capsule(capped_sv)
            sv = perl5.SvRV(rv)
            self.__perl_package__ = perl5.HvNAME(perl5.SvSTASH(sv)).decode("UTF-8")

        elif isinstance(capped_sv, basestring):
            sv = PyString2SV(ctx, capped_sv)
            self.perl_capped_sv = make_perl_sv_capsule(ctx.vm, sv)
            self.__perl_package__ = capped_sv

        self.__perl_members__ = {}

    def __perl_data__(self):
        cdef:
            perl5.SV *rv
            perl5.SV *sv

        rv = get_sv_from_capsule(self.perl_capped_sv)
        sv = perl5.SvRV(rv)
        return PerlSV2PyObject(self._context, sv)

    def can(self, name):
        if name in self.__perl_members__:
            return self.__perl_members__[name]

        ret = self._vm.call_method(self, "can", arguments=(name,))
        if isinstance(ret, CodeRefProxy):
            ret.set_object(self, name)

        self.__perl_members__[name] = ret

        return ret

    def isa(self, package):
        ret = self._vm.call_method(self, "isa", arguments=(package,))
        return ret

    def DOES(self, role):
        ret = self._vm.call_method(self, "DOES", arguments=(role,))
        return ret

    def new(self, arguments=None, method="new"):
        ret = self._vm.new(self, arguments, method)
        return ret

    def __getattr__(self, key):
        ret = self.can(key)
        if not ret:
            raise AttributeError("Attibute {} is not defined".format(key))
        return ret

cdef class CodeRefProxy(BaseProxy):
    cdef readonly object __invocant__
    cdef readonly object __subroutine_name__

    def __cinit__(self, Context ctx, object capped_sv, name=None, *args, **kwargs):
        perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)
        cdef perl5.SV *rv = get_sv_from_capsule(capped_sv)
        cdef perl5.SV *sv = perl5.SvRV(rv)
        self.__perl_package__ = perl5.HvNAME(perl5.CvSTASH(sv)).decode("UTF-8")
        if name:
            self.__subroutine_name__ = name
        else:
            self.__subroutine_name__ = perl5.GvNAME(perl5.CvGV(sv)).decode("UTF-8")

    def __call__(self, *args, **kwargs):
        invocant = self.__invocant__
        if invocant:
            subroutine = self.__subroutine_name__
        else:
            subroutine = self

        if args:
            return self._vm.call_method(invocant, subroutine, args)
        elif kwargs:
            return self._vm.call_method(invocant, subroutine, kwargs)
        else:
            return self._vm.call_method(invocant, subroutine, None)

    def set_object(self, package_or_proxy, name=None):
        self.__invocant__ = package_or_proxy
        if name:
            self.__subroutine_name__ = name

    def __repr__(self):
        package = self.__perl_package__
        if self.__invocant__:
            package = self.__invocant__
        else:
            package = self.__perl_package__
        return "{0}.{1}({2}::{3}) at 0x{4:x}".format(
            self.__class__.__module__, self.__class__.__name__,
            package, self.__subroutine_name__, id(self))

    def __dealloc__(self):
        self.__invocant__ = None
        self.__subroutine_name__ = None

cdef class ObjectPTR:
    cdef readonly object obj

    def __init__(self, obj):
        self.obj = obj

cdef class TypeMapper:
    BIGINT_PACKAGE = "Math::BigInt"
    COMPLEX_PACKAGE = "Math::Complex"
    FILE_PACKAGE = "IO::File"
    PROXY_PACKAGE = "PyPerl5::Proxy"

    object_proxy = Proxy
    coderef_proxy = CodeRefProxy

    cdef readonly VM vm

    def __init__(self, vm):
        self.vm = vm
        vm.use(self.FILE_PACKAGE, lazy=True)
        vm.use(self.BIGINT_PACKAGE, {"try": "GMP"}, lazy=True)
        vm.use(self.COMPLEX_PACKAGE, {}, lazy=True)
        vm.use(self.PROXY_PACKAGE, lazy=True)

    cdef object make_package_proxy(self, Context ctx, object package):
        proxy_cls = self.object_proxy
        return proxy_cls(ctx, package)

    cdef object make_proxy(self, Context ctx, perl5.SV *sv):
        perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)
        proxy_cls = None

        if perl5.SvOBJECT(perl5.SvRV(sv)):
            proxy_cls = self.object_proxy

        elif perl5.SvTYPE(perl5.SvRV(sv)) == perl5.SVt_PVCV:
            proxy_cls = self.coderef_proxy

        if proxy_cls:
            capped_sv = make_perl_sv_capsule(ctx.vm, sv)
            return proxy_cls(ctx, capped_sv)

    def map_long_integer(self, ctx, obj):
        return self.vm.new(self.BIGINT_PACKAGE, (str(obj),))

    def map_complex(self, ctx, obj):
        return self.vm.new(self.COMPLEX_PACKAGE, (obj.real, obj.imag))

    def map_from_python(self, ctx, obj):
        if isinstance(obj, IOBase) and hasattr(obj, "fileno") and hasattr(obj, "mode"):
            ret = self.vm.new(self.FILE_PACKAGE)
            fd = os.dup(obj.fileno())
            ret.fdopen(fd, obj.mode)
            return ret

        return self.vm.new(self.PROXY_PACKAGE, (ObjectPTR(obj),))

        # raise TypeError(str(type(obj)) + " is not supported type")

    def map_to_python(self, ctx, ref):
        if ref.isa(self.BIGINT_PACKAGE):
            return long(ref.bstr())

        if ref.isa(self.COMPLEX_PACKAGE):
            real, imag = ref._cartesian()
            return complex(float(real), float(imag))

        if ref.isa(self.FILE_PACKAGE):
            fd = os.dup(ref.fileno())
            return os.fdopen(fd, "r")

        # ref is subclass of BaseProxy
        return ref


cdef class Loader:
    PACKAGE = "PyPerl5::Loader"
    SCRIPT_LOADER_METHOD = "load"
    MODULE_LOADER_METHOD = "load_module"

    cdef readonly VM vm
    cdef readonly str package

    def __init__(self, vm):
        self.vm = vm
        self._lazy_loads = {}
        self.package = self.PACKAGE
        self.script_loader = self.SCRIPT_LOADER_METHOD
        self.module_loader = self.MODULE_LOADER_METHOD

    def lazy_load_check(self, package):
        return package in self._lazy_loads

    def require(self, script_name):
        ret = self.vm.call_method(self.package, self.script_loader, (script_name,))
        return ret

    def use(self, module_name, args=None, version=None, lazy=False):
        if lazy:
            self._lazy_loads[module_name] = (args, version)
            return True

        if module_name in self._lazy_loads:
            args, version = self._lazy_loads.pop(module_name)

        ret = self.vm.call_method(self.package, self.module_loader, (module_name, args, version,))
        return ret

    def path(self):
        return self.vm.get("@INC")

    def loaded(self):
        return self.vm.get("%INC")

cdef class _VMManager:
    cdef readonly int count

    def __cinit__(self):
        cdef:
            int argc = 0
            char ** argv
            char ** env

        perl5.PERL_SYS_INIT3(&argc, &argv, &env)

    def __dealloc__(self):
        perl5.PERL_SYS_TERM()

    def up(self):
        self.count += 1

    def down(self):
        self.count -= 1

ctypedef api class VM[object PyPerl5VM, type PyPerl5VMType]:
    _manager = _VMManager()

    cdef perl5.PerlInterpreter *my_perl
    cdef readonly bint closed
    cdef public Loader loader
    cdef public TypeMapper type_mapper
    cdef readonly object _vm_lock

    def __cinit__(self, *args, **kwargs):
        # VM initialize
        perl5.INIT_MY_PERL()
        cdef perl5.PerlInterpreter *my_perl

        if not perl5.PL_do_undump:
            my_perl = perl5.perl_alloc()
            self.my_perl = my_perl
            if not my_perl:
                raise MemoryError("can not allocation for Perl VM")

            perl5.SET_MY_PERL(my_perl)
            perl5.perl_construct(my_perl)

            perl5.PERL5_MODULE_SET_ORIGALEN(1)

            perl5.PERL5_MODULE_SET_EXIT_FLAGS(perl5.PERL_EXIT_DESTRUCT_END)

        self.closed = False
        self._manager.up()

    def __init__(self, type loader_class=Loader, type type_mapper_class=TypeMapper, include_directory=None):
        perl5.INIT_SET_MY_PERL(self.my_perl)
        cdef int exit_status
        cdef char ** c_boot_args
        cdef perl5.PerlInterpreter *vm
        cdef perl5.SV *sv_version

        self._vm_lock = RLock()

        self.loader = loader_class(self)
        vm = self.my_perl

        boot_args = ["", "-M"+self.loader.package]
        if include_directory:
            if isinstance(include_directory, basestring):
                boot_args.append("-I"+include_directory)
            else:
                boot_args.extend(["-I"+p for p in include_directory])

        # perlembed docs use "0". but parse error.
        boot_args.extend(["-e", ""])

        c_boot_args = to_cstring_array(boot_args)
        exit_status = perl5.perl_parse(vm, perl5.perl5_module_xs_init, len(boot_args), c_boot_args, NULL)

        PyMem_Free(c_boot_args)

        if exit_status == 0:
            exit_status = perl5.perl_run(vm)

            sv_version = perl5.get_sv("PyPerl5::CALLED_FROM_PYTHON", perl5.GV_ADD)
            perl5.sv_setpvn(sv_version, VERSION, len(VERSION))
            perl5.SvREADONLY_on(sv_version)

            vm_ref = perl5.get_sv("PyPerl5::VMREF", perl5.GV_ADD)
            perl5.sv_setiv(vm_ref, perl5.PTR2IV(<void*> self))
            perl5.SvREADONLY_on(vm_ref)

            # Init TypeMapper class
            if issubclass(type_mapper_class, TypeMapper):
                type_mapper = type_mapper_class(self)
                self.type_mapper = type_mapper

        else:
            raise RuntimeError(
                "perl_parse error. exit_status = ({}). boot_args = '{}'".format(exit_status, " ".join(boot_args)))

    def __dealloc__(self):
        if not self.closed and hasattr(self, "close"):
            self.close()

    def close(self):
        perl5.INIT_MY_PERL()
        cdef perl5.PerlInterpreter*vm
        cdef int i

        if self.closed:
            return True

        self.closed = True

        vm = self.my_perl

        if vm != NULL:
            perl5.SET_MY_PERL(vm)
            perl5.PERL5_MODULE_SET_DESTRUCT_LEVEL(1)
            perl5.perl_destruct(vm)
            perl5.perl_free(vm)
            self.my_perl = NULL
            self._manager.down()

        return True

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def _call(self, object package_or_proxy, object subroutine, object arguments, convert=True):
        perl5.INIT_SET_MY_PERL(self.my_perl)
        cdef:
            perl5.SV *sv
            vector[perl5.SV*] arg_stack
            perl5.I32 num_of_args = 0
            Py_ssize_t i

        if self.closed:
            raise PerlRuntimeError("Perl5VM is closed")

        ctx = Context(self, package_or_proxy, subroutine, arguments)

        if arguments:
            if isinstance(arguments, (list, tuple)):
                num_of_args += len(arguments)
            elif isinstance(arguments, dict):
                num_of_args += len(arguments) * 2
            else:
                num_of_args += 1

        if package_or_proxy is not None:
            num_of_args += 1
            # if isinstance(package_or_proxy, Proxy):
            #     repr(package_or_proxy)

        arg_stack.reserve(num_of_args)

        if package_or_proxy is not None:
            if isinstance(package_or_proxy, (basestring, BaseProxy)):
                if isinstance(package_or_proxy, basestring) and self.loader.lazy_load_check(package_or_proxy):
                    self.loader.use(package_or_proxy)
                __put_stack(ctx, package_or_proxy, arg_stack)

            else:
                raise RuntimeError("package_or_proxy is not package or proxy")

        if arguments is None:
            pass
        elif isinstance(arguments, (list, tuple, dict)):
            __put_stack(ctx, arguments, arg_stack)
        else:
            # __put_stack(ctx, arguments, arg_stack)
            raise TypeError("arguments is list, tuple or dict require")

        with self._vm_lock:
            ret = None
            perl5.PERL5_SETUP_CALL_SUB()

            if num_of_args:
                perl5.EXTEND(perl5.SP, num_of_args)
                for sv in arg_stack:
                    perl5.PUSHs(sv)
                perl5.PERL5_PUTBACK()

            num_of_args = __perl_call(ctx, package_or_proxy, subroutine)

            perl5.PERL5_SPAGAIN()

            try:
                if num_of_args == 1:
                    sv = perl5.PERL5_MODULE_POPs()

                    if convert:
                        ret = PerlSV2PyObject(ctx, sv)
                    else:
                        ret = self.type_mapper.make_proxy(ctx, sv)

                elif 1 < num_of_args:
                    ret = PyTuple_New(num_of_args)

                    for i in range(num_of_args):
                        sv = perl5.PERL5_MODULE_POPs()
                        if convert:
                            obj = PerlSV2PyObject(ctx, sv)
                        else:
                            obj = self.type_mapper.make_proxy(ctx, sv)
                        Py_INCREF(obj)
                        PyTuple_SET_ITEM(ret, num_of_args - i - 1, obj)
            finally:
                perl5.PERL5_CLEANUP_CALL_SUB()

            __perl_error_check(ctx)

        return ret

    def call_method(self, package_or_proxy, subroutine, arguments=None):
        return self._call(package_or_proxy, subroutine, arguments)

    def eval(self, script):
        perl5.INIT_SET_MY_PERL(self.my_perl)

        cdef perl5.SV *sv

        ctx = Context(self, None, "eval", None)
        sv = PyObject2PerlSV(ctx, script)

        with self._vm_lock:
            ret = None
            perl5.PERL5_SETUP_CALL_SUB()

            num_of_ret = perl5.eval_sv(sv, perl5.G_ARRAY | perl5.G_EVAL)

            perl5.PERL5_SPAGAIN()

            try:
                if num_of_ret == 1:
                    sv = perl5.PERL5_MODULE_POPs()
                    ret = PerlSV2PyObject(ctx, sv)

                elif 1 < num_of_ret:
                    ret = range(num_of_ret)
                    for i in range(num_of_ret):
                        sv = perl5.PERL5_MODULE_POPs()
                        obj = PerlSV2PyObject(ctx, sv)
                        ret[num_of_ret - i - 1] = obj
                    ret = tuple(ret)
            finally:
                perl5.PERL5_CLEANUP_CALL_SUB()

            __perl_error_check(ctx)

        return ret

    def get(self, name):
        perl5.INIT_SET_MY_PERL(self.my_perl)
        cdef perl5.SV *sv = NULL

        sigil = name[0]
        var_name = name[1:]

        if sigil == "$":
            sv = perl5.get_sv(var_name, 0)
        elif sigil == "@":
            sv = <perl5.SV*> perl5.get_av(var_name, 0)
        elif sigil == "%":
            sv = <perl5.SV*> perl5.get_hv(var_name, 0)
        elif sigil == "&":
            sv = <perl5.SV*> perl5.get_cv(var_name, 0)
            if sv != NULL:
                sv = <perl5.SV*> perl5.newRV_inc(sv)

        if sv != NULL:
            ctx = Context(self)
            return PerlSV2PyObject(ctx, sv)

    def new(self, package_or_proxy, arguments=None, method="new"):
        ret = self._call(package_or_proxy, method, arguments, convert=False)
        return ret

    def package(self, package):
        ctx = Context(self, package, None, None)
        return self.type_mapper.make_package_proxy(ctx, package)

    def require(self, script_name):
        return self.loader.require(script_name)

    def use(self, module_name, args=None, version=None, lazy=False):
        return self.loader.use(module_name, args, version, lazy)

cdef void init_perl5():
    libperl = dlfcn.dlopen("libperl.so", dlfcn.RTLD_LAZY | dlfcn.RTLD_GLOBAL)

    perl5.PTHREAD_ATFORK(
        perl5.Perl_atfork_lock, perl5.Perl_atfork_unlock, perl5.Perl_atfork_unlock)

cdef void finalize():
    perl5.PERL_SYS_TERM()

init_perl5()
