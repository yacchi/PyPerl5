# -*- coding: utf-8 -*-

# noinspection PyUnresolvedReferences,PyProtectedMember
cimport perl5
from cpython cimport *


cdef inline perl5.SV* PyNone2PerlSV(Context ctx):
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)
    return perl5.PERL5_MODULE_UNDEF()


cdef perl5.SV* PyString2SV(Context ctx, object string):
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef perl5.SV* sv

    uni = isinstance(string, unicode)

    if uni:
        string = string.encode("UTF-8")
    sv = perl5.newSVpvn(<char*>string, len(string))

    if uni:
        perl5.SvUTF8_on(sv)

    return sv


cdef perl5.SV* PyLong2PerlSV(Context ctx, object obj) except NULL:
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef int overflow = 0
    cdef perl5.IVTYPE num
    cdef perl5.UVTYPE unsigned_num

    num = perl5.PERL5_MODULE_PyLong2IVTYPE(obj, overflow)
    if overflow:
        if <perl5.IVTYPE>perl5.IV_MAX < obj <= <perl5.UVTYPE>perl5.UV_MAX:
            unsigned_num = perl5.PERL5_MODULE_PyLong2UVTYPE(obj)
            if 0 < unsigned_num:
                return perl5.newSVuv(unsigned_num)

        ret = ctx.vm.type_mapper.map_long_integer(ctx, obj)
        if ret and isinstance(ret, BaseProxy):
            sv = get_sv_from_capsule(ret.perl_capped_sv)
            perl5.SvREFCNT_inc(sv)
            return sv
        raise OverflowError
    return perl5.newSViv(num)


cdef perl5.SV* PyComplex2PerlSV(Context ctx, object obj) except NULL:
    ret = ctx.vm.type_mapper.map_complex(ctx, obj)
    if ret and isinstance(ret, BaseProxy):
        sv = get_sv_from_capsule(ret.perl_capped_sv)
        perl5.SvREFCNT_inc(sv)
        return sv


cdef perl5.SV* PyList2PerlRV(Context ctx, object obj) except NULL:
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef:
        perl5.AV *av = <perl5.AV*>perl5.sv_2mortal(<perl5.SV*>perl5.newAV())
        perl5.SV *sv
        perl5.SV **res
        Py_ssize_t i
        Py_ssize_t size = len(obj)

    if size:
        perl5.av_extend(av, size)

    for i in range(size):
        sv = PyObject2PerlSV(ctx, obj[i])

        res = perl5.av_store(av, i, sv)

        if res == NULL:
            perl5.av_undef(av)
            raise PerlRuntimeError("can't store array")

    return <perl5.SV*>perl5.newRV_inc(<perl5.SV*>av)


cdef perl5.SV* PyDict2PerlRV(Context ctx, object obj) except NULL:
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef:
        perl5.HV *hv = <perl5.HV*>perl5.sv_2mortal(<perl5.SV*>perl5.newHV())
        perl5.SV *sv_value

    for k, v in obj.items():
        sv_value = PyObject2PerlSV(ctx, v)

        if sv_value == perl5.PERL5_MODULE_UNDEF():
            sv_value = perl5.newSV(0)

        if not isinstance(k, basestring):
            k = str(k)

        perl5.hv_store_ent(hv, PyString2SV(ctx, k), sv_value, 0)

    return <perl5.SV*>perl5.newRV(<perl5.SV*>hv)


cdef api perl5.SV* PyObject2PerlSV(Context ctx, object obj) except NULL:
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef perl5.SV *sv = NULL

    if obj is None:
        sv = PyNone2PerlSV(ctx)

    elif isinstance(obj, basestring):
        sv = PyString2SV(ctx, obj)

    elif PyBool_Check(obj):
        pass

    elif isinstance(obj, (int, long)):
        sv = PyLong2PerlSV(ctx, obj)

    elif isinstance(obj, float):
        sv = perl5.newSVnv(obj)

    elif isinstance(obj, complex):
        sv = PyComplex2PerlSV(ctx, obj)
 
    elif isinstance(obj, (list, tuple)):
        sv = PyList2PerlRV(ctx, obj)

    elif isinstance(obj, dict):
        sv = PyDict2PerlRV(ctx, obj)

    elif isinstance(obj, BaseProxy):
        sv = get_sv_from_capsule(obj.perl_capped_sv)
        perl5.SvREFCNT_inc(sv)

    elif isinstance(obj, ObjectPTR):
        Py_INCREF(obj)
        sv = perl5.newSViv(perl5.PTR2IV(<void*>obj.obj))

    if sv == NULL:
        ret = ctx.vm.type_mapper.map_from_python(ctx, obj)
        if ret is not None:
            if isinstance(ret, BaseProxy):
                sv = get_sv_from_capsule(ret.perl_capped_sv)
                perl5.SvREFCNT_inc(sv)
            else:
                sv = PyObject2PerlSV(ctx, ret)

    if sv == NULL:
        raise TypeError("can't convert type = " + str(type(obj)))

    return sv


cdef object PerlSVScalar2PyObject(Context ctx, perl5.SV* sv):

    if perl5.SvPOK(sv):
        if perl5.SvUTF8(sv):
            return PyUnicode_FromStringAndSize(perl5.SvPVX(sv), perl5.SvCUR(sv))
        else:
            return PyBytes_FromStringAndSize(perl5.SvPVX(sv), perl5.SvCUR(sv))
    
    if perl5.SvIOK(sv):
        if perl5.SvIOK_UV(sv):
            return perl5.PERL5_MODULE_PyLongFromSVuv(sv)
        else:
            return perl5.PERL5_MODULE_PyLongFromSViv(sv)

    if perl5.SvNOK(sv):
        return perl5.SvNVX(sv)

    return


cdef inline object PerlSVRef2PyObject(Context ctx, perl5.SV *rv):
    return PerlSV2PyObject(ctx, perl5.SvRV(rv))


cdef inline object PerlObject2PyObject(Context ctx, perl5.SV *sv):
    return PerlSVScalar2PyObject(ctx, sv)


cdef object PerlAV2PyObject(Context ctx, perl5.SV *sv):
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef perl5.AV *av = <perl5.AV*>sv
    cdef perl5.SV **item_ptr
    cdef Py_ssize_t size = perl5.av_len(av) + 1, i
    cdef object o

    ret = []

    for i in range(size):
        item_ptr = perl5.av_fetch(av, i, 0)
        if item_ptr != NULL:
            o = PerlSV2PyObject(ctx, item_ptr[0])
            ret.append(o)
        else:
            ret.append(None)
    return ret


cdef PerlHV2PyObject(Context ctx, perl5.SV *sv):
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef perl5.HV *hv = <perl5.HV*>sv
    cdef perl5.HE *entry
    cdef object val

    ret = {}

    cdef perl5.I32 n = perl5.hv_iterinit(hv)

    for i in range(n):
        entry = perl5.hv_iternext(hv)
        val = PerlSV2PyObject(ctx, perl5.HeVAL(entry))
        ret[PerlSVScalar2PyObject(ctx, perl5.hv_iterkeysv(entry))] = val

    return ret


cdef api object PerlSV2PyObject(Context ctx, perl5.SV* sv):
    perl5.INIT_SET_MY_PERL(ctx.vm.my_perl)

    cdef int sv_type = perl5.SvTYPE(sv)
    cdef VM vm = ctx.vm

    if sv_type == perl5.SVt_RV and perl5.SvROK(sv):
        proxy = vm.type_mapper.make_proxy(ctx, sv)

        if proxy:
            if perl5.SvOBJECT(perl5.SvRV(sv)):
                return vm.type_mapper.map_to_python(ctx, proxy)
            return proxy

    if sv_type == perl5.SVt_NULL:
        return None

    elif sv_type == perl5.SVt_NV or (perl5.PERL_VERSION <= 10 and sv_type == perl5.SVt_IV):
        return PerlSVScalar2PyObject(ctx, sv)

    elif (sv_type in (perl5.SVt_PV, perl5.SVt_PVIV, perl5.SVt_PVNV)
        or sv_type == (perl5.SVt_RV if perl5.PERL_VERSION <= 10 else perl5.SVt_IV)
        or sv_type == perl5.SVt_PVBM and perl5.PERL_VERSION < 9):

        if perl5.SvROK(sv):
            return PerlSVRef2PyObject(ctx, sv)
        else:
            return PerlSVScalar2PyObject(ctx, sv)

    elif sv_type in (perl5.SVt_PVMG, perl5.SVt_PVLV):
        return PerlObject2PyObject(ctx, sv)

    elif sv_type == perl5.SVt_PVAV:
        # ARRAY
        return PerlAV2PyObject(ctx, sv)

    elif sv_type == perl5.SVt_PVHV:
        # HASH
        return PerlHV2PyObject(ctx, sv)

    else:
        pass

    raise PerlRuntimeError("convert error Perl to Python")
