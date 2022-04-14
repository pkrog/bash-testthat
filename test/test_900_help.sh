test_context "Testing help text"

TEST_DIR=$(dirname $BASH_SOURCE)
TEST_FILE=$(basename $BASH_SOURCE)
TEST_THAT_SCRIPT="$TEST_DIR/../testthat.sh"

function write_help {

	local file="$1"

	bash $TEST_THAT_SCRIPT -h >$file || return 1
}

function test_assertions_help {

	local n=0 # Number of non-documented assertions

	# Get help text
	help_file=$(mktemp -t $TEST_FILE.XXXXXX)
	expect_success write_help "$help_file"
	expect_non_empty_file "$help_file"

	# Loop on all defined assertion functions
	for assertion in $(grep -E '^ *function *(csv_)?expect_[^ ]+ *\{' "$TEST_THAT_SCRIPT" | sed -E 's/^ *function *((csv_)?expect_[^ ]+) *\{.*$/\1/') ; do

		# Is this a deprecated function?
		#grep -q '^ *function *'$assertion' *{ *# *DEPRECATED' $TEST_THAT_SCRIPT && continue

		# Does this assertion have documentation inside help text?
		expect_success grep -q '^ *'$assertion' *' "$help_file" || ((++n))
	done

	unlink $help_file

	expect_num_eq $n 0 || return 1
}
