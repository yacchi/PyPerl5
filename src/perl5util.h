#pragma once
// Perl headers
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>

#define PERL5_MODULE_SET_DESTRUCT_LEVEL(v) PL_perl_destruct_level = v
#define PERL5_MODULE_SET_ORIGALEN(v) PL_origalen = v
#define PERL5_MODULE_SET_EXIT_FLAGS(v) PL_exit_flags |= v
#define PERL5_MODULE_POPs() POPs
#define PERL5_MODULE_ERRSV() ERRSV
#define PERL5_MODULE_UNDEF() &PL_sv_undef
#define PERL5_MODULE_PL_STACK_SP() PL_stack_sp
#define PERL5_MODULE_SET_PL_STACK_SP(sp) PL_stack_sp = sp

#if IVSIZE == SIZEOF_LONG_LONG
#   define PERL5_MODULE_PyLong2IVTYPE(obj, overflow)  PyLong_AsLongLongAndOverflow(obj, &overflow)
#   if PY_MAJOR_VERSION < 3
#       define PERL5_MODULE_PyLongFromSViv(sv) (-INT_MAX <= SvIVX(sv) && SvIVX(sv) < INT_MAX) ? PyInt_FromLong(SvIVX(sv)) : PyLong_FromLongLong(SvIVX(sv))
#   else
#       define PERL5_MODULE_PyLongFromSViv(sv) PyLong_FromLongLong(SvIVX(sv));
#   endif
#else
#   define PERL5_MODULE_PyLong2IVTYPE(obj, overflow)  PyLong_AsLongAndOverflow(obj, &overflow)
#   if PY_MAJOR_VERSION < 3
#       define PERL5_MODULE_PyLongFromSViv(sv) (-INT_MAX <= SvIVX(sv) && SvIVX(sv) < INT_MAX) ? PyInt_FromLong(SvIVX(sv)) : PyLong_FromLong(SvIVX(sv))
#   else
#       define PERL5_MODULE_PyLongFromSViv(sv) PyLong_FromLong(SvIVX(sv));
#   endif
#endif

#if UVSIZE == SIZEOF_LONG_LONG
#   define PERL5_MODULE_PyLong2UVTYPE(obj)  PyLong_AsUnsignedLongLong(obj)
#   define PERL5_MODULE_PyLongFromSVuv(sv)  PyLong_FromUnsignedLongLong(SvUVX(sv));
#else
#   define PERL5_MODULE_PyLong2UVTYPE(obj)  PyLong_AsUnsignedLong(obj)
#   define PERL5_MODULE_PyLongFromSVuv(sv)  PyLong_FromUnsignedLong(SvUVX(sv));
#endif

#define PERL_SV_CAPSULE_NAME "PerlSV"

#define INIT_MY_PERL(p) PerlInterpreter *my_perl;
#define INIT_SET_MY_PERL(p) PerlInterpreter *my_perl = p; PERL_SET_CONTEXT(my_perl);
#define SET_MY_PERL(p) my_perl = p; PERL_SET_CONTEXT(my_perl);
#define PERL5_SETUP_CALL_SUB() dSP; ENTER; SAVETMPS; PUSHMARK(SP);
#define PERL5_CLEANUP_CALL_SUB() PUTBACK; FREETMPS; LEAVE;
#define PERL5_PUTBACK() PUTBACK;
#define PERL5_SPAGAIN() SPAGAIN;

#ifdef __cplusplus
extern "C" {
#endif

void perl5_module_xs_init(pTHX);
void perl5_module_unregister_signals(void);

#ifdef __cplusplus
}
#endif
