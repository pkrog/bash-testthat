all:

test:
	./testthat.sh test
	./testthat.sh test-testthat

clean:
	$(RM) -r test/workspace

.PHONY: all clean test
