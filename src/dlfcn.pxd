cdef extern from "dlfcn.h":
    void* dlopen(char*, int) nogil

    enum:
        RTLD_LAZY
        RTLD_NOW
        RTLD_GLOBAL
