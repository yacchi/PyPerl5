import sys
from typing import Union, Any, List, Optional, AnyStr

if 3 <= sys.version_info.major:
    long = int


class BaseProxy:
    def sv_dump(self) -> None: ...

    def __repr__(self) -> str: ...


class Proxy(BaseProxy):
    def can(self, name: AnyStr) -> bool: ...

    def isa(self, package: AnyStr) -> bool: ...

    def DOES(self, role: AnyStr) -> bool: ...

    def new(self, arguments: Any = None, method: AnyStr = "new") -> Proxy: ...

    def __getattr__(self, item: AnyStr) -> Any: ...

    def __perl_data__(self) -> Any: ...


class CodeRefProxy(BaseProxy):
    def __call__(self, *args, **kwargs) -> Any: ...


class ObjectPTR:
    """
    Wrap to perl reference type.
    """

    def __init__(self, obj: Any): ...


class Loader:
    package: AnyStr
    script_loader: AnyStr
    module_loader: AnyStr
    vm: VM

    def lazy_load_check(self, package: AnyStr) -> bool: ...

    def require(self, script_name: AnyStr) -> Any: ...

    def use(self, module_name: AnyStr,
            args: Union[AnyStr, List[AnyStr], None] = None,
            version: Optional[AnyStr] = None,
            lazy: bool = False,
            ) -> Any: ...

    def path(self) -> AnyStr: ...

    def loaded(self) -> bool: ...


class TypeMapper:
    BIGINT_PACKAGE: AnyStr = "Math::BigInt"
    COMPLEX_PACKAGE: AnyStr = "Math::Complex"
    FILE_PACKAGE: AnyStr = "IO::File"
    PROXY_PACKAGE: AnyStr = "PyPerl5::Proxy"

    object_proxy: Proxy
    coderef_proxy: CodeRefProxy

    vm: VM

    def map_long_integer(self, ctx: Context, obj: long) -> Union[Proxy, Any]:
        """
        Forward type mapping method.

        Python      Perl
        long   => Math::BigInt

        :param ctx: Context object
        :type ctx: Context
        :param obj: source object
        :type obj: object
        :return: converted object or Proxy
        :rtype: object or Proxy
        """
        ...

    def map_complex(self, ctx: Context, obj: complex) -> Union[Proxy, Any]:
        """
        Forward type mapping method.

        Python       Perl
        complex => Math::Complex

        :param ctx: Context object
        :type ctx: Context
        :param obj: source object
        :type obj: object
        :return: converted object or Proxy
        :rtype: object or Proxy
        """
        ...

    def map_from_python(self, ctx: Context, obj: Any) -> Union[Proxy, Any]:
        """
        Custom forward type mapping method.

        Python    Perl
        any    => any

        :param ctx: Context object
        :type ctx: Context
        :param obj: source object
        :type obj: object
        :return: converted object or perl object Proxy
        :rtype: object or Proxy
        """
        ...

    def map_to_python(self, ctx: Context, ref: Proxy) -> Union[BaseProxy, Any]:
        """
        Custom reverse type mapping method.

        Perl    Python
        any  => any

        :param ctx: Context object
        :type ctx: Context
        :param ref: perl object Proxy
        :type ref: Proxy
        :return: converted object or Proxy
        :rtype: object or Proxy
        """
        ...


class Context:
    def package(self) -> AnyStr: ...


class VM:
    type_mapper: TypeMapper
    loader: Loader
    closed: bool

    def __init__(self,
                 loader_cls=Loader,
                 type_mapper_cls=TypeMapper,
                 include_directory: AnyStr = "DEFAULT_PERL_LIB",
                 ): ...

    def close(self) -> bool: ...

    def __enter__(self) -> VM: ...

    def __exit__(self, exc_type, exc_val, exc_tb): pass

    def _call(self,
              package_or_proxy: Union[AnyStr, Proxy, None],
              subroutine: Union[AnyStr, CodeRefProxy],
              arguments: Any = None,
              convert=True,
              ) -> Any:
        ...

    # defined in perl5module.pyx

    def call_method(self,
                    package_or_proxy: Union[AnyStr, Proxy],
                    subroutine: Union[AnyStr, CodeRefProxy],
                    arguments: Any = None,
                    ) -> Any:
        ...

    def eval(self, script: AnyStr) -> Any:
        ...

    def get(self, name: AnyStr) -> Any: ...

    def new(self, package_or_proxy: Union[AnyStr, Proxy], arguments: Any = None, method: AnyStr = "new") -> Proxy:
        ...

    def package(self, package: AnyStr) -> Proxy:
        ...

    def require(self, script_name: AnyStr) -> Any:
        ...

    def use(self, module_name: AnyStr,
            args: Union[AnyStr, List[AnyStr], None] = None,
            version: Optional[AnyStr] = None,
            lazy: bool = False,
            ) -> Any: ...
