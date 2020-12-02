all:

test:
	./testthat.sh test
	./testthat.sh test-testthat.sh

clean:
	$(RM) -r test/workspace

.PHONY: all clean test
