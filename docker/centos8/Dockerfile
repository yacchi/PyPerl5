FROM centos:centos8.2.2004

RUN yum groupinstall -y "Development tools"
RUN mkdir -p /pyperl5

WORKDIR /pyperl5

RUN yum install -y vim-enhanced
RUN yum install -y epel-release
RUN yum install -y python2-pip python2-Cython python2-devel perl-devel perl-ExtUtils-Embed perl-Devel-PPPort
RUN yum install -y python3-pip python3-devel
RUN pip2 install -U pip && \
    pip2 install -U setuptools && \
    pip3 install -U pip && \
    pip3 install -U setuptools
RUN pip3 install Cython
RUN pip2 install pytest && \
    pip3 install pytest

COPY ../../setup.* MANIFEST.in README.rst ./
COPY ../../src ./src
COPY ../../tests ./tests
COPY ../../perl5 ./perl5
COPY ../../perl ./perl
