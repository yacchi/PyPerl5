FROM centos:centos7.9.2009

RUN yum groupinstall -y "Development tools"
RUN mkdir -p /pyperl5

WORKDIR /pyperl5

RUN yum install -y vim-enhanced
RUN yum install -y epel-release
RUN yum install -y python2-pip Cython python2-devel perl-devel perl-ExtUtils-Embed
RUN pip install -U pip wheel && \
    pip install -U setuptools
RUN pip install --ignore-installed pytest

COPY ../../setup.* MANIFEST.in README.rst ./
COPY ../../src ./src
COPY ../../tests ./tests
COPY ../../perl5 ./perl5
COPY ../../perl ./perl
