FROM centos:centos8.2.2004

RUN yum groupinstall -y "Development tools"
RUN mkdir -p /pyperl5

WORKDIR /pyperl5

RUN yum install -y python2-pip python2-Cython python2-devel perl-devel perl-ExtUtils-Embed perl-Devel-PPPort
RUN yum install -y python3-pip python3-devel
RUN pip2 install -U pip && \
    pip3 install -U pip --prefix /
RUN pip2 install -U setuptools wheel pytest && \
    pip3 install -U --prefix / setuptools wheel Cython tox pytest
RUN ln -s /usr/bin/python2 /usr/bin/python

COPY ../../setup.* MANIFEST.in tox.ini ./
COPY ../../src ./src
COPY ../../tests ./tests
COPY ../../perl5 ./perl5
COPY ../../perl ./perl
