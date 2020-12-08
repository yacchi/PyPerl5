FROM centos:centos7.9.2009

RUN yum groupinstall -y "Development tools"
RUN mkdir -p /pyperl5

WORKDIR /pyperl5

RUN yum install -y vim-enhanced
RUN yum install -y epel-release
RUN yum install -y python2-pip Cython python2-devel perl-devel perl-ExtUtils-Embed

COPY ../../setup.py MANIFEST.in README.rst ./
COPY ../../src ./src
COPY ../../test ./test
COPY ../../perl5 ./perl5
COPY ../../perl ./perl
