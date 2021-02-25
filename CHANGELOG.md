CHANGES IN VERSION 1.3.1
------------------------

NEW FEATURES

 * Test symbolic link.

CHANGES IN VERSION 1.3.0
------------------------

NEW FEATURES

 * new assertion `expect_failure_status`.
 * new assertion `expect_str_ne`.

USER SIGNIFICANT CHANGES

 * Replacement of `expect_success_after_n_tries` assertion by `expect_success_in_n_tries`.
 * All `csv_expect_.*` assertions have been replaced by `expect_csv_.*`.

DEPRECATION ANNOUNCEMENT

 * `expect_success_after_n_tries` assertion is now deprecated.
 * All `csv_expect_.*` assertions are now deprecated.

DOCUMENTATION

 * Writing of a documentation inside `README.md` and script help text.

TESTING

 * Integration of code coverage with codecov.
 * Testing of assertions documentation.
 * All testing moved inside test folder.
