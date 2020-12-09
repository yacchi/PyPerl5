clean:
	rm -r build || true
	rm src/perl5module.cpp src/perl5module.h src/perl5module_api.h src/ppport.h 2>/dev/null || true
	cd perl && make clean || true
	rm perl5/_lib/*.so || true
	rm -r perl5/vendor_perl/{auto,PyPerl5,.exists} || true

test-py2: clean
	python -B setup.py build
	python -B setup.py test

test-py3: clean
	python3 -B setup.py build
	python3 -B setup.py test

centos7:
	docker build -t pyperl5-build-env -f docker/centos7/Dockerfile .

centos7-py2: clean centos7
	docker run --rm -it pyperl5-build-env python2 setup.py build

centos7-py2-test: clean centos7
	docker run --rm -it pyperl5-build-env python2 setup.py test

centos8:
	docker build -t pyperl5-build-env-centos8 -f docker/centos8/Dockerfile .

centos8-py2: clean centos8
	docker run --rm -it pyperl5-build-env-centos8 python2 setup.py build

centos8-py2-test: clean centos8
	docker run --rm -it pyperl5-build-env-centos8 python2 setup.py test

centos8-py3: clean centos8
	docker run --rm -it pyperl5-build-env-centos8 python3 setup.py build

centos8-py3-test: clean centos8
	docker run --rm -it pyperl5-build-env-centos8 python3 setup.py test

all-test: centos7-py2-test centos8-py2-test centos8-py3-test