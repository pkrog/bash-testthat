test_context "Testing success/failure assertions"

function test_success {
	expect_success true  || return 1
}

function command_n_tries {
	((++I_TRIES))
	[[ $I_TRIES == $N_TRIES ]] || return 1
}

function test_expect_success_in_n_tries {

	I_TRIES=0 N_TRIES=3 expect_success_in_n_tries 3 command_n_tries || return 1

	# Deprecated function must still work
	I_TRIES=0 N_TRIES=3 expect_success_after_n_tries 3 command_n_tries || return 1
}

function test_failure {
	expect_failure false || return 1
}

function cmd_that_fails {
	local status=$1
	return $1
}

function test_failure_status {
	expect_failure_status 5 cmd_that_fails 5 || return 1
}

function test_exit {
	expect_exit exit 1 || return 1
}
