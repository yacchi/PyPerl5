#include <Python.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ppport.h>

#include <perl5module_api.h>

#define XS_STATE(type, sv)   (INT2PTR(type, SvIV(mg_find(SvRV(sv), PERL_MAGIC_ext)->mg_obj)))
#define PTRIV2OBJECT(type, sv) (INT2PTR(type, SvROK(sv) ? SvIV(SvRV(sv)) : SvIV(sv)))

#define XS_BEGIN_GIL PyGILState_STATE gstate; gstate = PyGILState_Ensure()
#define XS_END_GIL PyGILState_Release(gstate)

#define VM_INSTANCE PTRIV2OBJECT(PyPerl5VM*, get_sv("PyPerl5::VMREF", 0))
#define NEW_CTX(vm) new_py_perl5_context(vm)

static PyPerl5Context* new_py_perl5_context(PyPerl5VM *vm) {
    PyObject *arg = PyTuple_New(1);
    Py_INCREF((PyObject*)vm);
    PyTuple_SET_ITEM(arg, 0, (PyObject*)vm);
    PyObject *ctx = PyObject_Call((PyObject*)(&PyPerl5ContextType), arg, NULL);
    Py_DECREF(arg);
    return (PyPerl5Context*)ctx;
}

static PyObject* convert_args_from_sv_args(PyPerl5Context *ctx, SV* sv) {
    if (sv == NULL) {
        return Py_BuildValue("()");
    }

    PyObject *ret_list = PerlSV2PyObject(ctx, sv), *ret;

    if (ret_list != NULL) {
        ret = PyList_AsTuple(ret_list);
        Py_DECREF(ret_list);
    }
    return ret;
}

// #include <5.10>
MODULE = PyPerl5::Proxy		PACKAGE = PyPerl5::Proxy

BOOT:
    XS_BEGIN_GIL;
    // load perl5module_api
    import_perl5___lib___perl();
    XS_END_GIL;

void
_attach_py_object_ptr(self, py_object_ptr)
    SV *self;
    SV *py_object_ptr;
CODE:
    sv_magic(SvRV(self), py_object_ptr, PERL_MAGIC_ext, NULL, 0);
    SvREFCNT_inc(py_object_ptr);
    PyObject *py_self = XS_STATE(PyObject*, self);
    Py_INCREF(py_self);

void
_detach_py_object_ptr(self)
    SV *self;
CODE:
    PyObject *py_self = XS_STATE(PyObject*, self);
    sv_unmagic(SvRV(self), PERL_MAGIC_ext);
    Py_DECREF(py_self);

SV*
_get_py_object(self, module_name, attribute)
    SV *self;
    char *module_name;
    char *attribute;
CODE:
    XS_BEGIN_GIL;

    PyObject *module_name_obj = Py_BuildValue("s", module_name);
    PyObject *module = PyImport_Import(module_name_obj);
    Py_DECREF(module_name_obj);
    if (module == NULL) {
        XS_END_GIL;
        croak("module %s not found.", module_name);
    }

    PyObject *obj = PyObject_GetAttrString(module, attribute);
    if (obj == NULL) {
        XS_END_GIL;
        croak("%s.%s not found.", module_name, attribute);
    }

    PyPerl5VM *vm = VM_INSTANCE;
    PyPerl5Context *ctx = NEW_CTX(vm);
    RETVAL = PyObject2PerlSV(ctx, obj);

    Py_DECREF(obj);
    Py_DECREF(ctx);
    XS_END_GIL;
OUTPUT:
    RETVAL


SV*
can(self, name)
    SV *self;
    char *name;
CODE:
    XS_BEGIN_GIL;
    PyPerl5VM *vm = VM_INSTANCE;
    PyObject *py_self = XS_STATE(PyObject*, self);
    PyObject *func = PyObject_GetAttrString(py_self, name);
    if (func == NULL || !PyCallable_Check(func)) {
        PyErr_Clear();
        Py_XDECREF(func);
        RETVAL = &PL_sv_undef;
    } else {
        PyPerl5Context *ctx = NEW_CTX(vm);
        RETVAL = PyObject2PerlSV(ctx, func);
        Py_DECREF(func);
        Py_DECREF(ctx);
    }

    XS_END_GIL;
OUTPUT:
    RETVAL

void
exec(self, name, sv_args=NULL, sv_kwargs=NULL, ...)
    SV *self;
    char *name;
    SV *sv_args;
    SV *sv_kwargs;
PREINIT:
    Py_ssize_t i;
    SV *sv_ret;
    PyObject *args, *kwargs = NULL, *ret, *error, *ptype, *pvalue, *ptraceback;
    PyPerl5Context *ctx;

    XS_BEGIN_GIL;
PPCODE:
    PyPerl5VM *vm = VM_INSTANCE;
    PyObject *py_self = XS_STATE(PyObject*, self);
    PyObject *func = PyObject_GetAttrString(py_self, name);
    if (func == NULL) {
        XS_END_GIL;
        croak("method '%s' not found.", name);
    }

    ctx = NEW_CTX(vm);

    if (PyCallable_Check(func)) {
        args = convert_args_from_sv_args(ctx, sv_args);
        if (sv_kwargs != NULL)
            kwargs = PerlSV2PyObject(ctx, sv_kwargs);

        ret = PyObject_Call(func, args, kwargs);

        Py_DECREF(args);
        Py_XDECREF(kwargs);

        if (ret == NULL) {
            if (PyErr_Occurred()) {
                PyErr_Fetch(&ptype, &pvalue, &ptraceback);
                PyObject *v = PyObject_Str(pvalue);
                char *err =  PyBytes_AsString(v);
                Py_XDECREF(ptype);
                Py_XDECREF(pvalue);
                Py_XDECREF(ptraceback);
                Py_DECREF(func);
                Py_DECREF(ctx);
                XS_END_GIL;
                croak("call error (%s). %s\n ", name, err);
            }
        }
    } else {
        ret = func;
    }

    if (ret != NULL) {
//        PyObject *s = PyObject_Str(ret);
//        PerlIO_printf(PerlIO_stdout(), "ret = %s\n", PyString_AsString(s));
        sv_ret = PyObject2PerlSV(ctx, ret);
        mXPUSHs(sv_ret);
        Py_DECREF(ret);
    }

    Py_DECREF(func);
    Py_DECREF(ctx);
    XS_END_GIL;

    XSRETURN(ret == NULL ? 0 : 1);
