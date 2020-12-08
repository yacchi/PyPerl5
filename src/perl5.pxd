cdef extern from "<EXTERN.h>":
    pass


cdef extern from "<perl.h>":
    ctypedef struct SV:
        pass

    ctypedef struct AV:
        pass

    ctypedef struct RV:
        pass

    ctypedef struct HV:
        pass

    ctypedef struct HE:
        pass

    ctypedef struct CV:
        pass

    ctypedef struct GV:
        pass

    ctypedef struct XSUBADDR_t:
        pass

    ctypedef struct PerlInterpreter:
        pass

    ctypedef struct I32:
        pass

    ctypedef struct STRLEN:
        pass

    ctypedef Py_ssize_t I32

    ctypedef char* PL_sig_name

    ctypedef long IVTYPE
    ctypedef unsigned long UVTYPE

    void newXS(char*, XSUBADDR_t (*func)(), char*) nogil

    void Perl_atfork_lock() nogil
    void Perl_atfork_unlock() nogil
    void PERL_SYS_INIT3(int*, char***, char***) nogil
    void PERL_SYS_TERM() nogil
    void PTHREAD_ATFORK(void (*func)(), void (*func)(), void (*func)()) nogil

    PerlInterpreter* perl_alloc() nogil
    void PERL_SET_CONTEXT(PerlInterpreter*) nogil
    void perl_construct(PerlInterpreter*) nogil

    int perl_parse(PerlInterpreter*, void (*xs_init)(pTHX), int, char**, char**) nogil
    int perl_run(PerlInterpreter*) nogil

    void perl_destruct(PerlInterpreter*)
    void perl_free(PerlInterpreter*)

    # call
    I32 call_method(char*, int) nogil
    I32 call_sv(SV*, int) nogil
    I32 eval_sv(SV*, int) nogil

    # call flags
    enum: G_ARRAY
    enum: G_EVAL
    enum: G_NOARGS

    # SV control
    SV* newSV(int) nogil
    SV* get_sv(char*, I32) nogil
    SV* sv_setsv(SV*, SV*) nogil
    void sv_setpvn(SV*, char*, I32) nogil
    SV* newSVpvn(char*, I32) nogil
    SV* sv_2mortal(SV*) nogil
    void SvREFCNT_dec(SV*) nogil
    SV* SvREFCNT_inc(SV*) nogil
    int SvREFCNT(SV*) nogil
    char* SvPV(SV*, STRLEN) nogil
    int SvTRUE(SV*) nogil
    void sv_dump(SV*) nogil
    void SvREADONLY_on(SV*) nogil
    void SvREADONLY_off(SV*) nogil

    int SvTYPE(SV*) nogil

    HV* SvSTASH(SV*) nogil

    # PV control
    SV* newSVpvn(char*, I32) nogil
    SV* SvUTF8_on(SV*) nogil
    int SvPOK(SV*) nogil
    int SvUTF8(SV*) nogil
    char* SvPVX(SV*) nogil
    I32 SvCUR(SV*) nogil

    # IV/NV/UV control
    enum: IV_MAX
    enum: UV_MAX
    int SvIOK(SV*) nogil
    int SvIOK_UV(SV*) nogil
    long SvIV(SV*) nogil
    int SvNOK(SV*) nogil
    SV* newSViv(IVTYPE) nogil
    SV* newSVuv(UVTYPE) nogil
    SV* sv_setiv(SV*, IVTYPE) nogil
    IVTYPE PTR2IV(void*) nogil
    UVTYPE PTR2UV(void*) nogil

    double SvNVX(SV*) nogil
    SV* newSVnv(double) nogil

    # AV control
    AV* newAV() nogil
    SV** av_store(AV*, I32, SV*) nogil
    void av_extend(AV*, I32) nogil
    void av_undef(AV*) nogil
    int av_len(AV*) nogil
    SV** av_fetch(AV*, I32, I32) nogil
    void av_push(AV*, SV*) nogil
    AV* get_av(char*, I32) nogil

    # HV control
    HV* newHV() nogil
    SV** hv_store(HV*, char*, I32, SV*, int) nogil
    void hv_undef(HV*) nogil
    I32 hv_iterinit(HV*) nogil
    SV* hv_iternextsv(HV*, char**, I32*) nogil
    char* HvNAME(HV*) nogil
    char* HvNAME_get(HV*) nogil
    HV* get_hv(char*, I32) nogil

    # SV* based control
    HE* hv_store_ent(HV*, SV*, SV*, int) nogil
    HE* hv_iternext(HV*) nogil
    SV* hv_iterkeysv(HE*) nogil
    SV* HeSVKEY(HE*) nogil
    SV* HeVAL(HE*) nogil

    # RV control
    RV* newRV(SV*) nogil
    RV* newRV_inc(SV*) nogil
    SV* SvRV(SV*) nogil
    int SvROK(SV*) nogil

    # OBJECT control
    int SvOBJECT(SV*) nogil

    # Cv control
    HV* CvSTASH(SV*) nogil
    GV* CvGV(SV*) nogil
    CV* get_cv(char*, I32) nogil

    # Glob control
    char* GvNAME(GV*) nogil
    HV* GvSTASH(GV*) nogil

    # Stack control
    enum: dSP
    enum: ENTER
    enum: SAVETMPS
    enum: PUTBACK
    enum: SP
    enum: SPAGAIN
    enum: FREETMPS
    enum: LEAVE

    void PUSHs(SV*) nogil
    void mPUSHs(SV*) nogil
    void XPUSHs(SV*) nogil
    void mXPUSHs(SV*) nogil
    void PUSHMARK(int) nogil
    void EXTEND(int, int) nogil

    ctypedef void* pTHX

    enum: dXSUB_SYS
    enum: PERL_UNUSED_CONTEXT
    enum: pTHX
    enum: PL_do_undump
    enum: PL_perl_destruct_level
    enum: PL_origalen
    enum: PL_exit_flags

    enum: PERL_EXIT_DESTRUCT_END
    enum: GV_ADD

    # Consts
    enum: ERRSV
    enum: PERL_VERSION

    # svtype
    enum:
        SVt_NULL
        SVt_BIND
        SVt_IV
        SVt_NV
        SVt_PV
        SVt_PVIV
        SVt_PVNV
        SVt_PVMG
        SVt_REGEXP
        SVt_PVGV
        SVt_PVLV
        SVt_PVAV
        SVt_PVHV
        SVt_PVCV
        SVt_PVFM
        SVt_PVIO
        SVt_LAST

    enum:
        SVt_RV
        SVt_PVBM

    # debug
    void dump_all() nogil


cdef extern from "<XSUB.h>":
    pass


cdef extern from "ppport.h":
    pass


cdef extern from "perl5util.h":
    void PERL5_MODULE_SET_DESTRUCT_LEVEL(int) nogil
    void PERL5_MODULE_SET_ORIGALEN(int) nogil
    void PERL5_MODULE_SET_EXIT_FLAGS(int) nogil
    SV* PERL5_MODULE_POPs() nogil
    SV* PERL5_MODULE_ERRSV() nogil
    SV* PERL5_MODULE_UNDEF() nogil
    void INIT_MY_PERL() nogil
    void SET_MY_PERL(PerlInterpreter*) nogil
    void INIT_SET_MY_PERL(PerlInterpreter*) nogil

    SV** PERL5_MODULE_PL_STACK_SP() nogil
    PERL5_MODULE_SET_PL_STACK_SP(SV**) nogil
    PERL5_MODULE_SET_dSP(SV**) nogil

    IVTYPE PERL5_MODULE_PyLong2IVTYPE(object, int) nogil
    UVTYPE PERL5_MODULE_PyLong2UVTYPE(object) nogil
    object PERL5_MODULE_PyLongFromSViv(SV*) nogil
    object PERL5_MODULE_PyLongFromSVuv(SV*) nogil

    void perl5_module_xs_init(pTHX) nogil
    void PERL5_SETUP_CALL_SUB() nogil
    void PERL5_CLEANUP_CALL_SUB() nogil
    void PERL5_SPAGAIN() nogil
    void PERL5_PUTBACK() nogil

# cdef extern from *:
#     pass
