test_context "Testing success/failure assertions"

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
OUTPUT_DIR=$SCRIPT_DIR/output
mkdir -p "$OUTPUT_DIR"
NTRIES_FILE=$OUTPUT_DIR/ntries.txt

function test_success {
	expect_success true  || return 1
}

function command_n_tries {
	local i_tries=0
	[[ -f $NTRIES_FILE ]] && i_tries=$(cat "$NTRIES_FILE")
	((++i_tries))
	echo $i_tries >"$NTRIES_FILE"
	[[ $i_tries == 3 ]] || return 1
	return 0
}

function test_expect_success_in_n_tries {

	rm "$NTRIES_FILE"
	expect_success_in_n_tries 3 command_n_tries || return 1

	# Deprecated function must still work
	rm "$NTRIES_FILE"
	expect_success_after_n_tries 3 command_n_tries || return 1
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

function fct_that_exits {
	exit 1
}

function test_exit_in_fct {
	# The `exit` call must be handled/catched by the use of parenthesis.
	expect_failure fct_that_exits || return 1
}
