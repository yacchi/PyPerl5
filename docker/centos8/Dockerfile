FROM centos:centos8.2.2004

RUN yum groupinstall -y "Development tools"
RUN mkdir -p /pyperl5

WORKDIR /pyperl5

RUN yum install -y vim-enhanced
RUN yum install -y epel-release
RUN yum install -y python2-pip python2-Cython python2-devel perl-devel perl-ExtUtils-Embed perl-Devel-PPPort
RUN yum install -y python3-pip python3-devel && pip3 install Cython

COPY ../../setup.py MANIFEST.in README.rst ./
COPY ../../src ./src
COPY ../../test ./test
COPY ../../perl5 ./perl5
COPY ../../perl ./perl
