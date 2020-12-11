FROM centos:centos7.9.2009

RUN yum groupinstall -y "Development tools"
RUN mkdir -p /pyperl5

WORKDIR /pyperl5

RUN yum install -y vim-enhanced
RUN yum install -y epel-release
RUN yum install -y python2-pip Cython python2-devel perl-devel perl-ExtUtils-Embed
RUN yum install -y python3-pip python3-devel
RUN pip2 install -U pip && \
    pip3 install -U pip
RUN pip2 install -U --ignore-installed setuptools wheel pytest && \
    pip3 install -U setuptools wheel Cython tox pytest

COPY ../../setup.* MANIFEST.in README.rst tox.ini ./
COPY ../../src ./src
COPY ../../tests ./tests
COPY ../../perl5 ./perl5
COPY ../../perl ./perl
