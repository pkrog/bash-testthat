all:

test:
	./testthat.sh test
	./testthat.sh test/test_*.sh

testvm:
	teston -rD -f Makefile -f test -f testthat.sh  -c bash -c gnumake -t test\
		debian/bullseye64 ubuntu/bionic64 generic/freebsd12 generic/openbsd7

clean:
	$(RM) -r test/workspace

.PHONY: all clean test
