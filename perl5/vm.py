# -*- coding: utf-8 -*-
from __future__ import absolute_import

import datetime

# noinspection PyUnresolvedReferences,PyProtectedMember
from ._lib import _perl as perl5
from .vendor_perl import PERL_PACKAGE

__version__ = 1.0


class Loader(perl5.Loader):
    PACKAGE = "PyPerl5::Loader"


class Proxy(perl5.Proxy):
    pass


class CodeRefProxy(perl5.CodeRefProxy):
    pass


class TypeMapper(perl5.TypeMapper):
    BOOLEAN_PACKAGE = "PyPerl5::Boolean"

    object_proxy = Proxy
    coderef_proxy = CodeRefProxy

    def __init__(self, vm):
        super(TypeMapper, self).__init__(vm)

        vm.use(self.BOOLEAN_PACKAGE, lazy=True)
        self.date_time_package = None

    def __load_datetime_package(self):
        try:
            self.vm.use("DateTime")
            self.date_time_package = "DateTime"

            return
        except ImportError:
            pass

        try:
            self.vm.use("Time::Piece")
            self.date_time_package = "Time::Piece"

            return
        except ImportError:
            pass

    def map_from_python(self, ctx, obj):
        if isinstance(obj, bool):
            return self.vm.new(self.BOOLEAN_PACKAGE, method=("true" if obj else "false"))

        elif isinstance(obj, datetime.datetime):
            if self.date_time_package is None:
                self.__load_datetime_package()

            if self.date_time_package == "DateTime":
                args = {
                    "year": obj.year, "month": obj.month, "day": obj.day,
                    "hour": obj.hour, "minute": obj.minute, "second": obj.second,
                    "nanosecond": obj.microsecond * 1000,
                }
                if obj.tzname():
                    args["time_zone"] = obj.tzname()

                ret = self.vm.new("DateTime", args)
                return ret

            elif self.date_time_package == "Time::Piece":
                st = obj.timetuple()
                args = [st.tm_sec, st.tm_min, st.tm_hour, st.tm_mday, st.tm_mon - 1, st.tm_year - 1900,
                        st.tm_wday + 1, st.tm_yday - 1, 1 if obj.dst() else 0]
                return self.vm.new("Time::Piece", (args,))
            else:
                obj = obj.isoformat()

        return super(TypeMapper, self).map_from_python(ctx, obj)

    def map_to_python(self, ctx, ref):
        if ref.can("is_bool") and ref.is_bool():
            return True if ref.bool() else False

        if ref.isa("DateTime"):
            return datetime.datetime.fromtimestamp(ref.epoch() + (ref.microsecond() / 10 ** 6))

        if ref.isa("Time::Piece"):
            return datetime.datetime.fromtimestamp(ref.epoch())

        return super(TypeMapper, self).map_to_python(ctx, ref)


class VM(perl5.VM):
    def __init__(self, loader_cls=Loader, type_mapper_cls=TypeMapper, include_directory=PERL_PACKAGE):
        super(VM, self).__init__(loader_cls, type_mapper_cls, include_directory)

    def call(self, subroutine, *args, **kwargs):
        if args:
            ret = self._call(None, subroutine, args)
        elif kwargs:
            ret = self._call(None, subroutine, kwargs)
        else:
            ret = self._call(None, subroutine, None)
        return ret
