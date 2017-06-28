// Perl headers
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "perl5util.h"


EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

void
perl5_module_xs_init(pTHX)
{
    static const char file[] = __FILE__;

    // PERL_UNUSED_CONTEXT;
    dXSUB_SYS;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}
