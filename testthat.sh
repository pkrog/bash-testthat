#!/usr/bin/env bash

PROGNAME=$(basename $0)
VERSION=1.3.1
YES=yes
ON_THE_SPOT=on.the.spot
AT_THE_END=at.the.end
INCLUDE_FCTS=${TESTTHAT_INCLUDE_FCTS:-}
INCLUDE_FILES=${TESTTHAT_INCLUDE_FILES:-}

DEBUG=0
TOTEST=
NB_TEST_CONTEXT=0
ERR_NUMBER=0
PRINT=
FILE_PATTERN='[Tt][Ee][Ss][Tt][-._].*\.sh'
FCT_PREFIX='[Tt][Ee][Ss][Tt]_?'
AUTORUN=$YES
REPORT=$AT_THE_END
QUIT_ON_FIRST_ERROR=
declare -a g_err_msgs=()
declare -a g_err_stderr_files=()
declare -a g_fcts_run_in_test_file=()

function print_help {
	cat <<END_HELP
A bash script for running tests on command line scripts.

Usage: $PROGNAME [options] <folders or files>

The folders are searched for files matching 'test-*.sh' pattern.
You can use the environment variables TEST_THAT_FCT and TEST_THAT_NO_FCT to restrict the test functions that are run. Just set this variable to the list of functions you want to run or not run (separated by commas).

OPTIONS:

       --dryrun        List what tests would be run but do not execute anything.

   -f, --file-pattern  Redefine the regular expression for filtering test files
                       in folders. Default is "$FILE_PATTERN".

   -g, --debug         Debug mode.

   -h, --help          Print this help message.

       --no-autorun    Do not detect and run automatically the test functions.
                       This means you will have to call explicitly the
                       test_that function.

   -i, --include-fcts <fct1,fct2,...>
                       Set a selection of test functions to run. Only those test
                       functions will be run, if they exist. The value is a
                       comma separated list of functions names. Can be set also
                       through TESTTHAT_INCLUDE_FCTS environment variable.

   -j, --include-files <file1, file2, ...>
                       Set a selection of test files to run. Only those test
                       files will be run, if they exist. The value is a
                       comma separated list of files names. Can be set also
                       through TESTTHAT_INCLUDE_FILES environment variable.

   -p, --print         Print live output of test functions.

   -q, --quit-first    Quit on first error, and stop all tests.
                       Useful with $ON_THE_SPOT report (see -r option).

   -r, --report <NAME> Set the name of the reporter to use. Possible
                       values are: $ON_THE_SPOT (report each error as it
                       occurs), $AT_THE_END (report at the end of all
                       tests).
                       Default is $AT_THE_END.

   -v, --version       Print version.

   -x, --fct-prefix    Set the prefix to use when auto-detecting test
                       functions. Default is "$FCT_PREFIX".

WRITING A TEST SCRIPT:

   When inside a test script, you have first to define context:
      test_context "My context"
   The text of the context will be printed on the screen.

   Then you call test_that for each test function you have written:
      test_that "myFct is working correctly" test_myFct

   Inside your test_myFct function, you call assertions:
      function test_myFct {
         expect_num_eq 1 2 || return 1
      }
   Do not forget to append " || return 1" to the assertion call, otherwise no
   error will be reported in case of failure.

ASSERTIONS:

   Assertions start all with the prefix "expect_" and need to be followed by
   " || return 1" in order to report a failure.
   Some assertions take a custom message to be displayed in case of failure.

Success/failure assertions:

   expect_success   Test the success of a command.
                    Arguments: command.
                    Example:
                       expect_success my_command || return 1
                       expect_success my_command arg1 arg2 || return 1

   expect_success_in_n_tries
                    Test that a command succeeds before n tries.
                    Arg. 1: Number of tries.
                    Remaining arguments: command.
                    Example:
                       expect_success_in_n_tries 3 my_command || return 1
                       expect_success_in_n_tries 3 my_command arg1 || return 1

   expect_failure   Test the failure of a command.
                    Arguments: command.
                    Example:
                       expect_failure my_command || return 1
                       expect_failure my_command arg1 arg2 || return 1

   expect_status    Test that a command fails and return a precise status value.
                    Arg. 1: Expected status number.
                    Remaining arguments: command.
                    Example:
                       expect_status 0 my_command || return 1
                       expect_status 4 my_command || return 1
                       expect_status 4 my_command arg1 arg2 || return 1

   expect_exit      Test the failure of a command by running the command inside
                    a subshell. Thus you can test a call to a function that
                    call the \`exit\` command.
                    Arguments: command.
                    Example:
                       expect_exit my_command || return 1
                       expect_exit my_command arg1 arg2 || return 1

   expect_exit_status
                    Test that a command fails and return a precise status value
                    by running the command inside a subshell. Thus you can test
                    a call to a function that call the \`exit\` command.
                    Arg. 1: Expected status number.
                    Remaining arguments: command.
                    Example:
                       expect_exit_status 2 my_command || return 1
                       expect_exit_status 0 my_command arg1 arg2 || return 1

Output assertions:

   expect_empty_output
                    Test if a command output nothing on stdout.
                    Arguments: command.
                    Example:
                       expect_empty_output my_command arg1 arg2 || return 1

   expect_non_empty_output
                    Test if a command output something on stdout.
                    Arguments: command.
                    Example:
                       expect_non_empty_output my_command arg1 arg2 || return 1

   expect_output_eq Test if the output of a command is equals to a value. The
                    output is stripped from carriage returns before comparison.
                    Arg. 1: Expected output as a string.
                    Remaining arguments: command.
                    Example:
                       expect_output_eq "Expected Output" my_command arg1 arg2 || return 1

   expect_output_ne Test if the output of a command is equals to a value. The
                    output is stripped from carriage returns before comparison.
                    Arg. 1: Expected output as a string.
                    Remaining arguments: command.
                    Example:
                       expect_output_ne "Expected Output" my_command arg1 arg2 || return 1

   expect_output_esc_eq
                    Test if the output of a command is equals to a value.
                    Carriage returns are preserved.
                    Arg. 1: Expected output as a string for echo command with
                            trailing newline disabled and backslash escapes
                            enabled.
                    Remaining arguments: command.
                    Example:
                       expect_output_esc_eq "Expected Output" my_command arg1 arg2 || return 1

   expect_output_esc_ne
                    Test if the output of a command is different from a value.
                    Carriage returns are preserved.
                    Arg. 1: Expected output as a string for echo command with
                            trailing newline disabled and backslash escapes
                            enabled.
                    Remaining arguments: command.
                    Example:
                       expect_output_esc_ne "Expected Output" my_command arg1 arg2 || return 1

   expect_output_nlines_eq
                    Test if a command output exactly n lines of text on stdout.
                    Arg. 1: Expected number of lines.
                    Remaining arguments: command.
                    Example:
                       expect_output_nlines_eq 3 my_command arg1 arg2 || return 1

   expect_output_nlines_ge
                    Test if a command output n lines or more of text on stdout.
                    Arg. 1: Expected minimum number of lines.
                    Remaining arguments: command.
                    Example:
                       expect_output_nlines_ge 3 my_command arg1 arg2 || return 1

   expect_output_re Test if the output of a command matches a regular
                    expression. The output is stripped from carriage returns
                    before comparison.
                    Arg. 1: Regular expression.
                    Remaining arguments: command.
                    Example:
                       expect_output_re "A.*B" my_command arg1 arg2 || return 1

String assertions:

   expect_str_null  Test if a string is empty.
                    Arg. 1: String.
                    Arg. 2: Message (optional).
                    Example:
                       expect_str_null $$s || return 1
                       expect_str_null $$s "My Msg." || return 1

   expect_str_not_null
                    Test if a string is not empty.
                    Arg. 1: String.
                    Arg. 2: Message (optional).
                    Example:
                       expect_str_not_null $$s || return 1
                       expect_str_not_null $$s "My Msg." || return 1

   expect_str_eq    Test if two strings are equal.
                    Arg. 1: First string.
                    Arg. 2: Second string.
                    Arg. 3: Message (optional).
                    Example:
                       expect_str_eq $$s "abc" || return 1
                       expect_str_eq $$s "abc" "My Msg." || return 1

   expect_str_ne    Test if two strings are different.
                    Arg. 1: First string.
                    Arg. 2: Second string.
                    Arg. 3: Message (optional).
                    Example:
                       expect_str_ne $$s "abc" || return 1
                       expect_str_ne $$s "abc" "My Msg." || return 1

   expect_str_re    Test if a string matches an ERE.
                    Arg. 1: String.
                    Arg. 2: Pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_str_re $$s "^[a-zA-Z]+-[0-9]+$" || return 1
                       expect_str_re $$s "^[a-zA-Z]+-[0-9]+$" "My Msg" || return 1

Numeric assertions:

   expect_num_eq    Test the equality of two integers.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_eq $$n 2 || return 1
                       expect_num_eq $$n 2 "My Msg." || return 1

   expect_num_ne    Test that two integers are different.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_ne $$n 2 || return 1
                       expect_num_ne $$n 2 "My Msg." || return 1

   expect_num_le    Test that an integer is lower or equal than another.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_le $$n 5 || return 1
                       expect_num_le $$n 5 "My Msg" || return 1

   expect_num_gt    Test that an integer is strictly greater than another.
                    Arg. 1: First integer.
                    Arg. 2: Second integer.
                    Arg. 3: Message (optional).
                    Example:
                       expect_num_gt $$n 5 || return 1
                       expect_num_gt $$n 5 "My Msg" || return 1

Environment assertions:

   expect_def_env_var
                    Test if an environment variable is defined and not empty.
                    Arg. 1: Name of the environement variable.
                    Arg. 2: Message (optional).
                    Example:
                       expect_def_env_var MY_VAR || return 1
                       expect_def_env_var MY_VAR "My Msg" || return 1

File system assertions:

   expect_file      Test if file exists.
                    Arg. 1: File.
                    Arg. 2: Message (optional).
                    Example:
                       expect_folder "myFile" || return 1
                       expect_folder "myFile" "My Msg" || return 1

   expect_folder    Test if folder exists.
                    Arg. 1: Folder.
                    Arg. 2: Message (optional).
                    Example:
                       expect_folder "myFolder" || return 1
                       expect_folder "myFolder" "My Msg" || return 1

   expect_symlink   Test if a symbolic link exists and points to a certain
                    location.
                    Arg. 1: Symbolic link path.
                    Arg. 2: The path to which the link points.
                    Arg. 3: Message (optional).
                    Example:
                      expect_symlink "/my/sym/link" "/the/file/to/which/it/points"

   expect_no_path   Test if nothing exists (no file, no folder) at the
                    specified path.
                    Arg. 1: Path.
                    Arg. 2: Message (optional).
                    Example:
                       expect_no_path "myFolder" || return 1
                       expect_no_path "myFolder" "My Msg" || return 1

   expect_same_folders
                    Test if two folders have the same content, using "diff"
                    command.
                    Arg. 1: First folder.
                    Arg. 2: Second folder.
                    Example:
                       expect_same_folders "folderA" "folderB" || return 1

   expect_files_in_folder
                    Test if files matching a pattern exist inside a folder.
                    Arg. 1: Folder.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_files_in_folder "myFolder" "^.*\.txt$" || return 1
                       expect_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_other_files_in_folder
                    Test if a folder contains files not matching a pattern.
                    Arg. 1: Folder.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_other_files_in_folder "myFolder" "^.*\.txt$" || return 1
                       expect_other_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_no_other_files_in_folder
                    Test if a folder contains files matching a pattern, and no
                    other files.
                    Arg. 1: Folder.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_no_other_files_in_folder "myFolder" "^.*\.txt$" || return 1
                       expect_no_other_files_in_folder "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_files_in_tree
                    Test if files matching a pattern exist inside a tree structure.
                    Arg. 1: Folder in which to search recursively.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_files_in_tree "myFolder" "^.*\.txt$" || return 1
                       expect_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_other_files_in_tree
                    Test if files not matching a pattern exist inside a tree
                    structure, and no other files.
                    Arg. 1: Folder in which to search recursively.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_other_files_in_tree "myFolder" "^.*\.txt$" || return 1
                       expect_other_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_no_other_files_in_tree
                    Test if files matching a pattern exist inside a tree
                    structure, and no other files.
                    Arg. 1: Folder in which to search recursively.
                    Arg. 2: Files pattern as an ERE.
                    Arg. 3: Message (optional).
                    Example:
                       expect_no_other_files_in_tree "myFolder" "^.*\.txt$" || return 1
                       expect_no_other_files_in_tree "myFolder" "^.*\.txt$" "My Msg" || return 1

   expect_folder_is_writable
                    Test files can be created or modified inside a folder.
                    Arg. 1: Path to the folder.
                    Arg. 3: Message (optional).
                    Example:
                       expect_folder_is_writable "myFolder" "My Msg" || return 1

File assertions:

   expect_same_files
                    Test if two files are identical.
                    Arg. 1: File 1.
                    Arg. 2: File 2.
                    Example:
                       expect_same_files "myFile1" "myFile2" || return 1

   expect_empty_file
                    Test if a file exists and is empty.
                    Arg. 1: File.
                    Arg. 2: Message (optional).
                    Example:
                       expect_empty_file "myFile" || return 1

   expect_non_empty_file
                    Test if a file exists and is not empty.
                    Arg. 1: File.
                    Arg. 2: Message (optional).
                    Example:
                       expect_non_empty_file "myFile" || return 1

   expect_no_duplicated_row
                    Test if a file contains no duplicated rows.
                    Arg. 1: File.
                    Example:
                       expect_no_duplicated_row "myFile" || return 1

   expect_same_number_of_rows
                    Test if two files contain the same number of lines.
                    Arg. 1: File 1.
                    Arg. 2: File 2.
                    Example:
                       expect_same_number_of_rows "myFile1" "myFile2" || return 1

CSV assertions:

   expect_csv_has_columns
                    Test if a CSV file contains a set of columns. Second
                    argument is the separator character used in the CSV.
                    Arg. 1: File.
                    Arg. 2: CSV separator character.
                    Arg. 3: Expected column names separated by spaces.
                    Example:
                       expect_csv_has_columns "myfile.csv" "," "col1 col2 col3" || return 1

   expect_csv_not_has_columns
                    Test if a CSV file does not contain a set of columns.
                    Arg. 1: File.
                    Arg. 2: CSV separator character.
                    Arg. 3: Column names separated by spaces.
                    Example:
                       expect_csv_not_has_columns "myfile.csv" "," "col1 col2 col3" || return 1

   expect_csv_identical_col_values
                    Test if two CSV files contain the same column with the same
                    values.
                    Arg. 1: Column name.
                    Arg. 2: File 1.
                    Arg. 3: File 2.
                    Arg. 4: CSV separator character.
                    Example:
                       expect_csv_identical_col_values "myCol" "myFile1" "myFile2" ";" || return 1

   expect_csv_float_col_equals
                    Test if all the values of a CSV file column are close to a float value.
                    Arg. 1: File.
                    Arg. 2: CSV separator.
                    Arg. 3: Column name.
                    Arg. 4: Float value.
                    Arg. 5: Tolerance.
                    Example:
                       expect_csv_float_col_equals "myFile" "," "myCol" 10.01 0.01 || return 1

   expect_csv_same_col_names
                    Test if two CSV files contain the same column names.
                    Arg. 1: File 1.
                    Arg. 2: File 2.
                    Arg. 3: CSV separator.
                    Arg. 4: The number of columns on which to make the
                            comparison. If unset all columns will be used
                            (optional).
                    Arg. 5: If set to 1, then double quotes will be removed
                            from column names before comparison (optional).
                    Example:
                       expect_csv_same_col_names "myFile1" "myFile2" ";" || return 1
                       expect_csv_same_col_names "myFile1" "myFile2" ";" 8 || return 1
                       expect_csv_same_col_names "myFile1" "myFile2" ";" 8 1 || return 1

DEPRECATED ASSERTIONS:

   expect_failure_status
                       Replace by "expect_status".

   expect_file_exists  Replaced by "expect_file".

   expect_success_after_n_tries
                       Replaced by "expect_success_in_n_tries".

   csv_expect_has_columns
                       Replaced by "expect_csv_has_columns".

   csv_expect_not_has_columns
                       Replaced by "expect_csv_not_has_columns".

   csv_expect_identical_col_values
                       Replaced by "expect_csv_identical_col_values".

   csv_expect_float_col_equals
                       Replaced by "expect_csv_float_col_equals".

   csv_expect_same_col_names
                       Replaced by "expect_csv_same_col_names".

GLOSSARY

   ERE      Extended Regular Expression.

END_HELP
}

function error {

	local msg=$1

	echo "ERROR: $msg" >&2

	exit 1
}

function debug {

	local dbglvl=$1
	local dbgmsg=$2

	[ $DEBUG -ge $dbglvl ] && echo "[DEBUG] $dbgmsg" >&2
}

function deprecated {
	local new_fct="$1"
	debug 1 "Deprecated function. Use $new_fct() instead."
}

function read_args {

	local args="$*" # save arguments for debugging purpose

	# Read options
	while true ; do
		case $1 in
			--dryrun)           DRYRUN=1 ;;
			-f|--file-pattern)  FILE_PATTERN="$2" ; shift ;;
			-g|--debug)         DEBUG=$((DEBUG + 1)) ;;
			-h|--help)          print_help ; exit 0 ;;
			--no-autorun)       AUTORUN= ;;
			-i|--include-fcts)  INCLUDE_FCTS="$2" ; shift ;;
			-j|--include-files) INCLUDE_FILES="$2" ; shift ;;
			-p|--print)         PRINT=$YES ;;
			-q|--quit-first)    QUIT_ON_FIRST_ERROR=$YES ;;
			-r|--report)        REPORT="$2" ; shift ;;
			-v|--version)       echo $VERSION ; exit 0 ;;
			-x|--fct-prefix)    FCT_PREFIX="$2" ; shift ;;
			-) error "Illegal option $1." ;;
			--) error "Illegal option $1." ;;
			--*) error "Illegal option $1." ;;
			-?) error "Unknown option $1." ;;
			-[^-]*) split_opt=$(echo $1 | sed 's/^-//' | sed 's/\([a-zA-Z]\)/ -\1/g') ; set -- $1$split_opt "${@:2}" ;;
			*) break
		esac
		shift
	done

	# Read remaining arguments as a list of folders and/or files
	if [ -n "$*" ] ; then
		TOTEST=("$@")
	else
		TOTEST=()
	fi

	# Check reporter
	[[ $REPORT == $AT_THE_END || $REPORT == $ON_THE_SPOT ]] || error "Unknown reporter $REPORT."

	# Debug
	debug 1 "Arguments are : $args"
	debug 1 "Folders and files to test are : $TOTEST"
	debug 1 "AUTORUN=$AUTORUN"
	debug 1 "DEBUG=$DEBUG"
	debug 1 "FCT_PREFIX=$FCT_PREFIX"
	debug 1 "FILE_PATTERN=$FILE_PATTERN"
	debug 1 "INCLUDE_FCTS=$INCLUDE_FCTS"
	debug 1 "INCLUDE_FILES=$INCLUDE_FILES"
	debug 1 "REPORT=$REPORT"
}

function join_by {
	local IFS="$1"
	shift
	echo "$*"
}

function test_context {

	local msg=$1

	if [[ -z $DRYRUN ]] ; then

		[[ $NB_TEST_CONTEXT -gt 0 ]] && echo
		echo -n "$msg "
		((++NB_TEST_CONTEXT))
	fi
}

print_error() {
	n=$1
	msg="$2"
	output_file="$3"

	echo
	echo '----------------------------------------------------------------'
	printf "%x. " $n
	echo "Failure while asserting that \"$msg\"."
	echo '---'
	if [[ -f $output_file ]] ; then
		cat "$output_file"
		rm "$output_file"
	fi
	echo '----------------------------------------------------------------'
}

finalize_tests() {

	# Print new line
	[[ $NB_TEST_CONTEXT -eq 0 ]] || echo

	# Print end report
	[[ $REPORT == $AT_THE_END ]] && print_end_report

	# Exit
	exit $ERR_NUMBER
}

function test_that {

	local msg="$1"
	local test_fct="$2"
	shift 2
	local params="$*"
	local tmp_stderr_file=$(mktemp -t testthat-stderr.XXXXXX)

	# Filtering
	if [[ -n $TEST_THAT_FCT && ",$TEST_THAT_FCT," != *",$test_fct,"* ]] ; then
		return 0
	fi
	if [[ -n $TEST_THAT_NO_FCT && ",$TEST_THAT_NO_FCT," == *",$test_fct,"* ]] ; then
		return 0
	fi

	# Run test
	g_fcts_run_in_test_file+=("$test_fct")
	( $test_fct $params 2>"$tmp_stderr_file" ) # Run in a subshell to catch exit
	                                           # interruptions.
	exit_code=$?

	# Set message
	[[ -n $msg ]] || msg="Tests pass in function $test_fct"

	# Print stderr now
	[[ $PRINT == $YES && -f $tmp_stderr_file ]] && cat $tmp_stderr_file

	# Failure
	if [ $exit_code -gt 0 ] ; then

		# Increment error number
		((++ERR_NUMBER))

		# Print error number
		if [[ ERR_NUMBER -lt 16 ]] ; then
			printf %x $ERR_NUMBER
		else
			echo -n E
		fi

		# Print error now
		if [[ $REPORT == $ON_THE_SPOT ]] ; then
			print_error $ERR_NUMBER "$msg" "$tmp_stderr_file"

		# Store error message for later
		else
			g_err_msgs+=("$msg")
			g_err_stderr_files+=("$tmp_stderr_file")
		fi

		# Quit on first error
		[[ $QUIT_ON_FIRST_ERROR == $YES ]] && finalize_tests

	# Success
	else
		rm $tmp_stderr_file
	fi
}

function run_test_file {

	local file="$1"

	[[ -z $DRYRUN ]] || echo "Test functions found in file \"$file\":"

	g_fcts_run_in_test_file=()
	source "$file"

	# Run all test_.* functions not run explicitly by test_that
	if [[ $AUTORUN == $YES ]] ; then
		for fct in $(grep -E '^ *function +'$FCT_PREFIX'[^ ]+|'$FCT_PREFIX'[^ ]+\(\) *\{' "$file" | sed -E 's/^ *(function +)?('$FCT_PREFIX'[^ {(]+).*$/\2/') ; do

			# Ignore some reserved names
			[[ $fct == test_context || $fct == test_that ]] && continue

			# Filtering
			[[ -z $INCLUDE_FCTS || ",$INCLUDE_FCTS," == *",$fct,"* ]] || continue

			# Run function
			[[ " ${g_fcts_run_in_test_file[*]} " == *" $fct "* ]] && continue
			if [[ -n $DRYRUN ]] ; then
				echo "  $fct"
			else
				test_that "" $fct
			fi
		done
	fi
}

function print_end_report {

	if [[ $ERR_NUMBER -gt 0 ]] ; then
		echo '================================================================'
		echo "$ERR_NUMBER error(s) encountered."

		# Loop on all errors
		for ((i = 0 ; i < ERR_NUMBER ; ++i)) ; do
			print_error $((i+1)) "${g_err_msgs[$i]}" "${g_err_stderr_files[$i]}"
		done
	fi
}

output_progress() {
	# Output the progress of a command, by taking both stdout and stderr of the
	# command and replace each line by a dot character.
	# This function is useful while some part of the test code takes much time
	# and use does not get any feedback.
	# It is also particularly essential with Travis-CI, which aborts the test
	"$@" 2>&1 | while read line ; do echo -n . ; done
}

function print_call_stack {

	local frame=0
	while caller $frame >&2 ; do
		((frame++));
	done
}

function expect_success_in_n_tries {

	local n=$1
	shift
	local cmd="$*"

	# Try to run the command
	for ((i = 0 ; i < n ; ++i)) ; do
		( "$@" >&2 )
		err=$?
		[[ $err == 0 ]] && break
	done

	# Failure
	if [[ $err -gt 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed $n times." >&2
		return 1
	fi

	echo -n .
}

function expect_success {

	local cmd="$*"

	( "$@" >&2 )
	local status=$?

	if [[ $status -gt 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	fi

	echo -n .
}

function expect_failure {

	local cmd="$*"

	( "$@" >&2 )

	if [[ $? -eq 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" was successful while expecting failure." >&2
		return 1
	fi

	echo -n .
}

function expect_status {

	local expected_status="$1"
	shift
	local cmd="$*"

	( "$@" >&2 )
	local actual_status=$?

	if [[ $actual_status -ne $expected_status ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $actual_status, but " \
			"expected status $expected_status." >&2
		return 2
	fi

	echo -n .
}

function expect_empty_output {

	local cmd="$*"
	local output=
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	output=$(cat "$tmpfile")
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ -n $output ]] ; then
		print_call_stack >&2
		echo "Output of \"$cmd\" is not empty. Output: \"$output\"." >&2
		return 2
	fi

	echo -n .
}

function expect_non_empty_output {

	local cmd="$*"
	local empty=
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	[[ -s "$tmpfile" ]] || empty=$YES
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ $empty == $YES ]] ; then
		print_call_stack >&2
		echo "Output of \"$cmd\" is empty." >&2
		return 2
	fi

	echo -n .
}

function _expect_output_op {

	local op="$1"
	local expected_output="$2"
	shift 2
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?
	local output=$(cat "$tmpfile")
	rm "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ $op == eq && "$expected_output" != "$output" ]] ; then
		print_call_stack >&2
		echo "Output of \"$cmd\" is wrong. Expected \"$expected_output\". Got \"$output\"." >&2
		return 2
	elif [[ $op == ne && "$expected_output" == "$output" ]] ; then
		print_call_stack >&2
		echo "Output of \"$cmd\" is wrong. Expected something different from \"$expected_output\"." >&2
		return 3
	elif [[ $op == re ]] && ! egrep "$expected_output" >/dev/null <<<"$output" ; then
		print_call_stack >&2
		echo "Output of \"$cmd\" is wrong. Expected \"$expected_output\". Got \"$output\"." >&2
		return 4
	fi

	echo -n .
}

function expect_output_eq {
	_expect_output_op 'eq' "$@"
	return $?
}

function expect_output_re {
	_expect_output_op 're' "$@"
	return $?
}

function expect_output_ne {
	_expect_output_op 'ne' "$@"
	return $?
}

function _expect_output_esc_op {

	local op="$1"
	local expected_output="$2"
	shift 2
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)
	local tmpfile2=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	echo -ne "$expected_output" >"$tmpfile2"

	if [[ $status -ne 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		rm "$tmpfile" "$tmpfile2"
		return 1
	elif [[ $op == eq ]] && ! diff -q "$tmpfile" "$tmpfile2" ; then
		print_call_stack >&2
		echo -n "Output of \"$cmd\" is wrong. Expected \"$expected_output\". Got \"" >&2
		cat $tmpfile >&2
		echo "\"." >&2
		rm "$tmpfile" "$tmpfile2"
		return 2
	elif [[ $op == ne ]] && diff -q "$tmpfile" "$tmpfile2" ; then
		print_call_stack >&2
		echo -n "Output of \"$cmd\" is wrong. Expected something different from \"$expected_output\"." >&2
		rm "$tmpfile" "$tmpfile2"
		return 3
	fi

	rm "$tmpfile" "$tmpfile2"
	echo -n .
}

function expect_output_esc_ne {
	_expect_output_esc_op 'ne' "$@"
	return $?
}

function expect_output_esc_eq {
	_expect_output_esc_op 'eq' "$@"
	return $?
}

function expect_output_nlines_eq {

	local n="$1"
	shift
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	local nlines=$(awk 'END { print NR }' "$tmpfile")
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ $nlines -ne $n ]] ; then
		print_call_stack >&2
		echo "Output of \"$cmd\" contains $nlines lines, not $n." >&2
		return 2
	fi

	echo -n .
}

function expect_output_nlines_ge {

	local n="$1"
	shift
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	local nlines=$(wc -l <"$tmpfile")
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ ! $nlines -ge $n ]] ; then
		print_call_stack >&2
		echo "Output of \"$cmd\" contains less than $n lines. It contains $nlines lines." >&2
		return 2
	fi

	echo -n .
}

function csv_get_col_index {

	local file=$1
	local sep=$2
	local col_name=$3

	n=$(head -n 1 "$file" | tr "$sep" "\n" | egrep -n "^\"?${col_name}\"?\$" | sed 's/:.*$//')

	if [[ -z $n ]] ; then
		n=-1
	fi

	echo $n
}

function csv_count_values {

	local file=$1
	local sep=$2
	local col=$3

	col_index=$(csv_get_col_index $file $sep $col)
	[[ $col_index -gt 0 ]] || return 1
	nb_values=$(awk "BEGIN{FS=\"$sep\"}{if (NR > 1 && \$$col_index != \"NA\") {++n}} END{print n}" $file)

	echo $nb_values
}

function csv_get_nb_cols {

	local file=$1
	local sep=$2

	echo $(head -n 1 "$file" | tr "$sep" "\n" | wc -l)
}

function csv_get_col_names {

	local file=$1
	local sep=$2
	local ncol=$3
	local remove_quotes=$4
	local cols=

	if [[ -z $ncol || $ncol -le 0 ]] ; then
		cols=$(head -n 1 "$file")
	else
		cols=$(head -n 1 "$file" | tr "$sep" "\n" | head -n $ncol | tr "\n" "$sep")
	fi

	# Remove quotes
	if [[ $remove_quotes -eq 1 ]] ; then
		cols=$(echo $cols | sed 's/"//g')
	fi

	echo $cols
}

function csv_get_val {

	local file=$1
	local sep=$2
	local col=$3
	local row=$4

	col_index=$(csv_get_col_index $file $sep $col)
	[[ $col_index -gt 0 ]] || return 1
	val=$(awk 'BEGIN{FS="'$sep'"}{ if (NR == '$row' + 1) {print $'$col_index'} }' $file)

	echo $val
}

function expect_csv_has_columns {

	local file=$1
	local sep=$2
	local expected_cols=$3

	# Get columns
	cols=$(csv_get_col_names $file $sep 0 1)

	# Loop on all expected columns
	for c in $expected_cols ; do
		if [[ " $cols " != *" $c "* && " $cols " != *" \"$c\" "* ]] ; then
			print_call_stack >&2
			echo "Column \"$c\" cannot be found inside columns of file \"$file\"." >&2
			echo "Columns of file \"$file\" are: $cols." >&2
			return 1
		fi
	done

	echo -n .
}

function expect_csv_not_has_columns {

	local file=$1
	local sep=$2
	local expected_cols=$3

	# Get columns
	cols=$(csv_get_col_names $file $sep 0 1)

	# Loop on all expected columns
	for c in $expected_cols ; do
		if [[ " $cols " == *" $c "* || " $cols " == *" \"$c\" "* ]] ; then
			print_call_stack >&2
			echo "Column \"$c\" has been found inside columns of file \"$file\"." >&2
			echo "Columns of file \"$file\" are: $cols." >&2
			return 1
		fi
	done

	echo -n .
}

function expect_csv_identical_col_values {

	local col=$1
	local file1=$2
	local file2=$3
	local sep=$4

	col1=$(csv_get_col_index $file1 $sep $col)
	expect_num_gt $col1 0 "\"$file1\" does not contain column $col."
	col2=$(csv_get_col_index $file2 $sep $col)
	expect_num_gt $col2 0 "\"$file2\" does not contain column $col."
	ncols_file1=$(csv_get_nb_cols $file1 $sep)
	((col2 = col2 + ncols_file1))
	ident=$(paste $file1 $file2 | awk 'BEGIN{FS="'$sep'";eq=1}{if ($'$col1' != $'$col2') {eq=0}}END{print eq}')
	if [[ $ident -ne 1 ]] ; then
		print_call_stack >&2
		echo "Files \"$file1\" and \"$file2\" do not have the same values in column \"$col\"." >&2
		return 1
	fi
}

function csv_expect_same_col_names {

	local file1=$1
	local file2=$2
	local sep=$3
	local nbcols=$4
	local remove_quotes=$5

	cols1=$(csv_get_col_names $file1 $sep $nbcols $remove_quotes)
	cols2=$(csv_get_col_names $file2 $sep $nbcols $remove_quotes)
	if [[ $cols1 != $cols2 ]] ; then
		print_call_stack >&2
		echo "Column names of files \"$file1\" and \"$file2\" are different." >&2
		[[ -n $nbcols ]] && echo "Comparison on the first $nbcols columns only." >&2
		echo "Columns of file \"$file1\" are: $cols1." >&2
		echo "Columns of file \"$file2\" are: $cols2." >&2
		return 1
	fi

	echo -n .
}

function expect_csv_float_col_equals {

	local file=$1
	local sep=$2
	local col=$3
	local val=$4
	local tol=$5

	col_index=$(csv_get_col_index $file $sep $col)
	ident=$(awk 'function abs(v) { return v < 0 ? -v : v }BEGIN{FS="'$sep'";eq=1}{if (NR > 1 && abs($'$col_index' - '$val') > '$tol') {eq=0}}END{print eq}' $file)

	[[ $ident -eq 1 ]] || return 1
}

function expect_empty_file {

	local file="$1"
	local msg="$2"

	if [[ ! -f $file || -s $file ]] ; then
		print_call_stack >&2
		echo "\"$file\" does not exist, is not a file or is not empty. $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_non_empty_file {

	local file="$1"
	local msg="$2"

	if [[ ! -f $file || ! -s $file ]] ; then
		print_call_stack >&2
		echo "\"$file\" does not exist, is not a file or is empty. $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_same_files {

	local file1="$1"
	local file2="$2"

	expect_file "$file1" || return 2
	expect_file "$file2" || return 3

	if ! diff -q "$file1" "$file2" >/dev/null ; then
		print_call_stack >&2
		echo "Files \"$file1\" and \"$file2\" differ." >&2
		return 1
	fi

	echo -n .
}

function get_nb_rows {

	local file=$1
	local header=$2

	n=$(wc -l <$1)

 	# Deduct header line
	if [[ -n $header && $header -ne 0 ]] ; then
		((n=n-1))
	fi

	echo $n
}

function expect_same_number_of_rows {

	local file1=$1
	local file2=$2

	if [[ $(get_nb_rows $file1) -ne $(get_nb_rows $file2) ]] ; then
		print_call_stack >&2
		echo "\"$file1\" and \"$file2\" do not have the same number of rows." >&2
		return 1
	fi

	echo -n .
}

function expect_no_duplicated_row {

	local file=$1

	nrows=$(cat $file | wc -l)
	n_uniq_rows=$(sort -u $file | wc -l)
	[[ $nrows -eq $n_uniq_rows ]] || return 1
}

function expect_str_null {

	local v=$1
	local msg="$2"

	if [[ -n $v ]] ; then
		print_call_stack >&2
		echo "String \"$v\" is not null ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_str_not_null {

	local v=$1
	local msg="$2"

	if [[ -z $v ]] ; then
		print_call_stack >&2
		echo "String is null ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_str_eq {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ $a != $b ]] ; then
		print_call_stack >&2
		echo "\"$a\" == \"$b\" not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_str_ne {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ $a == $b ]] ; then
		print_call_stack >&2
		echo "\"$a\" != \"$b\" not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_str_re {

	local str="$1"
	local re="$2"
	local msg="$3"

	local s=$(echo "$str" | egrep "$re")
	if [[ -z $s ]] ; then
		print_call_stack >&2
		echo "\"$str\" not matched by regular expression \"$re\" ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_num_eq {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -eq $b ]] ; then
		print_call_stack >&2
		echo "$a == $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_num_ne {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -ne $b ]] ; then
		print_call_stack >&2
		echo "$a != $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_num_le {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -le $b ]] ; then
		print_call_stack >&2
		echo "$a <= $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_num_gt {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -gt $b ]] ; then
		print_call_stack >&2
		echo "$a > $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_def_env_var {

	local varname="$1"
	local msg="$2"

	if [[ -z "${!varname}" ]] ; then
		print_call_stack >&2
		echo "Env var $varname is not defined or is empty ! $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_no_path {

	local path="$1"
	local msg="$2"

	if [[ -e $path ]] ; then
		print_call_stack >&2
		echo "\"$path\" exists. $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_folder {

	local folder="$1"
	local msg="$2"

	if [[ ! -d $folder ]] ; then
		print_call_stack >&2
		echo "\"$folder\" does not exist or is not a folder. $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_file {

	local file="$1"
	local msg="$2"

	if [[ ! -f $file ]] ; then
		print_call_stack >&2
		echo "\"$file\" does not exist or is not a file. $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_symlink {

	local symlink="$1"
	local pointed_path="$2"
	local msg="$3"

	if [[ ! -h $symlink ]] ; then
		print_call_stack >&2
		echo "\"$symlink\" does not exist or is not a symbolic link. $msg" >&2
		return 1
	else
		local path=$(realpath "$symlink")
		local real_pointed_path=$(realpath "$pointed_path")
		if [[ $path != $real_pointed_path ]] ; then
			print_call_stack >&2
			echo "Symbolic link \"$symlink\" does not point to \"$pointed_path\" but to \"$path\". $msg" >&2
			return 1
		fi
	fi

	echo -n .
}

function expect_folder_is_writable {

	local folder="$1"
	local msg="$2"
	local file="$folder/.___testthat_test_file___"

	if ! touch "$file" ; then
		print_call_stack >&2
		echo "Folder \"$folder\" is not writable. $msg" >&2
		return 1
	fi

	unlink "$file"
	echo -n .
}

function expect_other_files_in_folder {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	cd "$folder"
	files=$(ls -1 | egrep -v "$files_regex")
	cd "$prevdir"
	if [[ -z $files ]] ; then
		print_call_stack >&2
		echo "No files, not matching \"$files_regex\", were found inside folder \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_other_files_in_tree {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	files=$(find "$folder" -type f | xargs -n 1 basename | egrep -v "$files_regex")
	if [[ -z $files ]] ; then
		print_call_stack >&2
		echo "No files, not matching \"$files_regex\", were found inside folder tree \"$tree\". $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_no_other_files_in_tree {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	files_matching=$(find "$folder" -type f | sed 's/.*/"&"/' | xargs -n 1 basename | egrep "$files_regex")
	files_not_matching=$(find "$folder" -type f | sed 's/.*/"&"/' | xargs -n 1 basename | egrep -v "$files_regex")
	if [[ -z $files_matching ]] ; then
		print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder tree \"$folder\". $msg" >&2
		return 1
	fi
	if [[ -n $files_not_matching ]] ; then
		print_call_stack >&2
		echo "Files, not matching \"$files_regex\", were found inside folder \"$folder\": $files_not_matching. $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_no_other_files_in_folder {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	cd "$folder"
	files_matching=$(ls -1 | egrep "$files_regex")
	files_not_matching=$(ls -1 | egrep -v "$files_regex")
	cd "$prevdir"
	if [[ -z $files_matching ]] ; then
		print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder \"$folder\". $msg" >&2
		return 1
	fi
	if [[ -n $files_not_matching ]] ; then
		print_call_stack >&2
		echo "Files, not matching \"$files_regex\", were found inside folder \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_files_in_tree {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	files=$(find "$folder" -type f | xargs -n 1 basename | egrep "$files_regex")
	if [[ -z $files ]] ; then
		print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder tree \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_files_in_folder {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	cd "$folder"
	files=$(ls -1 | egrep "$files_regex")
	cd "$prevdir"
	if [[ -z $files ]] ; then
		print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function expect_same_folders {

	local folder1="$1"
	local folder2="$2"

	expect_folder "$folder1" || return 2
	expect_folder "$folder2" || return 3

	if ! diff -r -q "$folder1" "$folder2" >/dev/null ; then
		print_call_stack >&2
		echo "Folders \"$folder1\" and \"$folder2\" differ." >&2
		return 1
	fi

	echo -n .
}

function expect_failure_status { # DEPRECATED
	deprecated "expect_status"
	expect_status "$@" || return 1 
}

function csv_expect_same_col_names { # DEPRECATED
	deprecated "expect_csv_same_col_names"
	expect_csv_same_col_names "$@" || return 1 
}

function csv_expect_float_col_equals { # DEPRECATED
	deprecated "expect_csv_float_col_equals"
	expect_csv_float_col_equals "$@" || return 1 
}

function csv_expect_identical_col_values { # DEPRECATED
	deprecated "expect_csv_identical_col_values"
	expect_csv_identical_col_values "$@" || return 1 
}

function csv_expect_has_columns { # DEPRECATED
	deprecated "expect_csv_has_columns"
	expect_csv_has_columns "$@" || return 1 
}

function csv_expect_not_has_columns { # DEPRECATED
	deprecated "expect_csv_not_has_columns"
	expect_csv_not_has_columns "$@" || return 1 
}

function expect_success_after_n_tries { # DEPRECATED
	deprecated "expect_success_in_n_tries"
	expect_success_in_n_tries "$@" || return 1
}

function expect_file_exists { # DEPRECATED
	deprecated "expect_file"
	expect_file "$@" || return 1
}

function run_tests {

	# Loop on folders and files to test
	for e in ${TOTEST[@]} ; do

		[[ -f $e || -d $e ]] || error "\"$e\" is neither a file nor a folder."

		# File
		[[ -f $e ]] && run_test_file "$e"

		# Folder
		if [[ -d $e ]] ; then
			local tmp_file=$(mktemp -t $PROGNAME.XXXXXX)
			ls $e/* | sort >$tmp_file
			while read f ; do

				# Check file pattern
				[[ -f $f && $f =~ ^[^/]*/$FILE_PATTERN$ ]] || continue

				# Filter
				local filename=$(basename "$f")
				[[ -z $INCLUDE_FILES || ",$INCLUDE_FILES," == *",$filename,"* ]] || continue

				# Run tests in file
				run_test_file "$f"
			done <$tmp_file
		fi

	done
}

function main {

	# Read arguments
	read_args "$@"

	# Run
	run_tests

	# Finalize
	finalize_tests
}

main "$@"
exit 0
