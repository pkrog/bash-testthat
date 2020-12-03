all:

test:
	./testthat.sh test
	./testthat.sh test/test_*.sh

clean:
	$(RM) -r test/workspace

.PHONY: all clean test
