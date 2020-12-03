# bash-testthat

[![Build Status](https://travis-ci.org/pkrog/bash-testthat.svg?branch=master)](https://travis-ci.org/pkrog/bash-testthat)
[![codecov](https://codecov.io/gh/pkrog/bash-testthat/branch/master/graph/badge.svg?token=4QNHAHECYQ)](https://codecov.io/gh/pkrog/bash-testthat)

A test framework for bash, in the style of R package [testthat](https://github.com/hadley/testthat).
It is designed to help you write tests for a command line program, written in any language, or to test bash functions.

In particular, the framework provides functions for testing CSV files that you use as inputs or outputs of your program.

## Usage

*bash-testthat* can be run on individual test scripts or folders containing test scripts.
You can even specify a mix of them on the command line:
```sh
bash-testthat/testthat.sh myfirst_script.sh myfolderA mysecond_script.sh myfolderB
```

### Running individual test scripts

Running individual scripts is done by listing the script paths on the command line:
```sh
bash-testthat/testthat.sh myfirst_script.sh mysecond_script.sh my/other/script.sh
```
The scripts will be run in the specified order.

### Running all test scripts in a folder

Put your test scripts inside a single folder. We will name it `test` in this example.

Then write your scripts inside this folder and name them `test-*.sh`.

To run the tests call by giving the test folder path to the `testthat.sh` script:
```sh
bash-testthat/testthat.sh test
```
Only the scripts named `test-*.sh` will be run by *bash-testthat*.
The scripts will be run in **alphabetical order**.

The exact regular expression used by *bash-testthat* is: `[Tt][Ee][Ss][Tt][-._].*\.sh`.
Thus you have a little flexibility in naming your test files by default.
If this is not sufficient, you can still redefine this pattern by using the `-f` command line argument.
The pattern format must be a POSIX extended regular expression as required by the `=~` comparison operator provided by the `[[` bash command.

### Writing a test script

A test scripts is composed of functions in which assertions (i.e.: the tests) are written.
The functions are called individually with some description message that will be printed in case of failure.

Here is a full example:
```sh
function test_someStuff {
	expect_num_eq 1 2 || return 1
}

test_context "Running some test for an example"
test_that "Some stuff is running correctly." test_someStuff
```
The `test_context` call define a title for the tests that will follow. It will be printed in the output.
The `test_that` function calls the test function `test_someStuff` and in case of failure will display the message specified.
Inside the `test_someStuff` function you have to call assertions in order to test code.

In this example we use the assertion `expect_num_eq` (all assertions start with `expect_` as a prefix), which tests the equality of two numeric numbers.
In our case the two numbers `1` and `2` will lead to a failure of the test.
But, please, note that in order to activate the failure it is **compulsory** to append ` || return 1` to the assertion call, otherwise no failure will be reported.

Each assertion will either lead to the printing of a dot (`.`) character in case of success or another character in case of failure.
At the end of tests, each character printed to indicate a failure will again be printed along with the message provided to the `test_that` call and the call stack.

For a full list of assertions, see the help text (`testthat.sh -h`).
