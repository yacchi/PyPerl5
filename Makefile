clean:
	rm -r build || true
	rm src/perl5module.cpp src/perl5module.h src/perl5module_api.h src/ppport.h 2>/dev/null || true
	cd perl && make clean || true
	rm perl5/_lib/*.so || true
	rm -r perl5/vendor_perl/{auto,PyPerl5,.exists} || true

test: clean
	tox -v

centos7:
	docker build -t pyperl5-build-env-centos7 -f docker/centos7/Dockerfile .

centos7-py2-test: clean centos7
	docker run --rm -it pyperl5-build-env-centos7 python2 setup.py test

centos7-py3-test: clean centos7
	docker run --rm -it pyperl5-build-env-centos7 python3 setup.py test

centos7-test: clean centos7
	docker run --rm -it pyperl5-build-env-centos7 tox -e py27,py36

centos8:
	docker build -t pyperl5-build-env-centos8 -f docker/centos8/Dockerfile .

centos8-py2-test: clean centos8
	docker run --rm -it pyperl5-build-env-centos8 python2 setup.py test

centos8-py3-test: clean centos8
	docker run --rm -it pyperl5-build-env-centos8 python3 setup.py test

centos8-test: clean centos8
	docker run --rm -it pyperl5-build-env-centos8 tox -e py27,py36

all-test: centos7-test centos8-test