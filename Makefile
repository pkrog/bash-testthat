all:

test:
	./testthat.sh test
	./testthat.sh test/test_*.sh

testvm:
	teston -r -s Makefile -s test -s testthat.sh debian/bullseye64 ubuntu/bionic64 generic/freebsd12

clean:
	$(RM) -r test/workspace

.PHONY: all clean test
