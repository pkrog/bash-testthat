all:

test:
	./testthat.sh test
	./testthat.sh test/test_*.sh

testvm:
	teston -urD debian11 ubuntu18 freebsd12 Makefile test testthat.sh

clean:
	$(RM) -r test/workspace

.PHONY: all clean test
