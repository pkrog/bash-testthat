#!/bin/bash
# vi: fdm=marker

# Constants {{{1
################################################################

PROGNAME=$(basename $0)
VERSION=1.2.0
YES=yes
ON_THE_SPOT=on.the.spot
AT_THE_END=at.the.end

# Global variables {{{1
################################################################

DEBUG=0
TOTEST=
NB_TEST_CONTEXT=0
ERR_NUMBER=0
PRINT=
FILE_PATTERN='[Tt][Ee][Ss][Tt][-._].*\.sh'
FCT_PREFIX='[Tt][Ee][Ss][Tt]_\?'
AUTORUN=$YES
REPORT=$AT_THE_END
QUIT_ON_FIRST_ERROR=
declare -a g_err_msgs=()
declare -a g_err_stderr_files=()
declare -a g_fcts_run_in_test_file=()

# Print help {{{1
################################################################

function print_help {
	cat <<END_HELP
Usage: $PROGNAME [options] <folders or files>

The folders are searched for files matching 'test-*.sh' pattern.
You can use the environment variables TEST_THAT_FCT and TEST_THAT_NO_FCT to restrict the test functions that are run. Just set this variable to the list of functions you want to run or not run (separated by commas).

Options:

   -f, --file-pattern  Redefine the regular expression for filtering test files
                       in folders. Default is "$FILE_PATTERN".

   -g, --debug         Debug mode.

   -h, --help          Print this help message.

       --no-autorun    Do not detect and run automatically the test functions.
                       This means you will have to call explicitly the
                       test_that function.

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

Writing a test script:

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

Assertions:
   Assertions start all with the prefix "expect_" and need to be followed by
   " || return 1" in order to report a failure.

   expect_num_eq    Test the equality of two numeric numbers. Example:
                       expect_num_eq $$n 2 || return 1
END_HELP
}

# Error {{{1
################################################################

function error {

	local msg=$1

	echo "ERROR: $msg" >&2

	exit 1
}

# Print debug msg {{{1
################################################################

function print_debug_msg {

	local dbglvl=$1
	local dbgmsg=$2

	[ $DEBUG -ge $dbglvl ] && echo "[DEBUG] $dbgmsg" >&2
}

# Read args {{{1
################################################################

function read_args {

	local args="$*" # save arguments for debugging purpose

	# Read options
	while true ; do
		case $1 in
			-f|--file-pattern)  FILE_PATTERN="$2" ; shift ;;
			-g|--debug)         DEBUG=$((DEBUG + 1)) ;;
			-h|--help)          print_help ; exit 0 ;;
			   --no-autorun)    AUTORUN= ;;
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
	print_debug_msg 1 "Arguments are : $args"
	print_debug_msg 1 "Folders and files to test are : $TOTEST"
	print_debug_msg 1 "AUTORUN=$AUTORUN"
	print_debug_msg 1 "FCT_PREFIX=$FCT_PREFIX"
	print_debug_msg 1 "FILE_PATTERN=$FILE_PATTERN"
}

# Test context {{{1
################################################################

function test_context {

	local msg=$1

	[[ $NB_TEST_CONTEXT -gt 0 ]] && echo

	echo -n "$msg "

	((NB_TEST_CONTEXT=NB_TEST_CONTEXT+1))
}

# Print error {{{1
################################################################

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

# Finalize tests {{{1
################################################################

finalize_tests() {

	# Print new line
	[[ $NB_TEST_CONTEXT -eq 0 ]] || echo

	# Print end report
	[[ $REPORT == $AT_THE_END ]] && print_end_report

	# Exit
	exit $ERR_NUMBER
}

# Test that {{{1
################################################################

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
	$test_fct $params 2>"$tmp_stderr_file"
	exit_code=$?

	# Set message
	[[ -n $msg ]] || msg="Tests pass in function $test_fct"

	# Print stderr now
	[[ $PRINT == $YES && -f $tmp_stderr_file ]] && cat $tmp_stderr_file

	# Failure
	if [ $exit_code -gt 0 ] ; then

		# Increment error number
		((ERR_NUMBER=ERR_NUMBER+1))

		# Print error number
		if [[ ERR_NUMBER -lt 16 ]] ; then
			printf %x $ERR_NUMBER
		else
			echo -n E
		fi

		# Print error now
		if [[ $REPORT == $ON_THE_SPOT ]] ; then
			print_error $ERR_NUMBER "$msg" "$tmp_output_file"

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

# Run test file {{{1
################################################################################

function run_test_file {

	local file="$1"

	g_fcts_run_in_test_file=()
	source "$file"

	# Run all test_.* functions not run explicitly by test_that
	if [[ $AUTORUN == $YES ]] ; then
		for fct in $(grep '^ *\(function \+'$FCT_PREFIX'[^ ]\+\|'$FCT_PREFIX'[^ ]\+()\) *{' "$file" | sed 's/^ *\(function \+\)\?\('$FCT_PREFIX'[^ {(]\+\).*$/\2/') ; do
			[[ $fct == test_context || $fct == test_that ]] && continue
			[[ " ${g_fcts_run_in_test_file[*]} " == *" $fct "* ]] || test_that "" $fct
		done
	fi
}

# Print end report {{{1
################################################################

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

# Output progress {{{1
# Output the progress of a command, by taking both stdout and stderr of the
# command and replace each line by a dot character.
# This function is useful while some part of the test code takes much time
# and use does not get any feedback.
# It is also particularly essential with Travis-CI, which aborts the test
# if no output has been seen for the last 10 minutes.
################################################################

output_progress() {
	"$@" 2>&1 | while read line ; do echo -n . ; done
}

# Print call stack {{{1
################################################################

function print_call_stack {

	local frame=1
	while caller $frame ; do
		((frame++));
	done
}

# CSV get column index  {{{1
################################################################

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

# CSV count values {{{1
################################################################

function csv_count_values {

	local file=$1
	local sep=$2
	local col=$3

	col_index=$(csv_get_col_index $file $sep $col)
	[[ $col_index -gt 0 ]] || return 1
	nb_values=$(awk "BEGIN{FS=\"$sep\"}{if (NR > 1 && \$$col_index != \"NA\") {++n}} END{print n}" $file)

	echo $nb_values
}

# CSV get number of columns {{{1
################################################################

function csv_get_nb_cols {

	local file=$1
	local sep=$2

	echo $(head -n 1 "$file" | tr "$sep" "\n" | wc -l)
}

# CSV get column names {{{1
################################################################

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


# Get number of rows {{{1
################################################################

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

# CSV get value {{{1
################################################################

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

# Expect success after n tries {{{1
################################################################

function expect_success_after_n_tries {

	local n=$1
	shift
	local cmd="$*"

	# Try to run the command
	for ((i = 0 ; i < n ; ++i)) ; do
		"$@" >&2
		err=$?
		[[ $err == 0 ]] && break
	done

	# Failure
	if [[ $err -gt 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed after $n tries." >&2
		return 1
	fi

	echo -n .
}

# Expect success {{{1
################################################################

function expect_success {

	local cmd="$*"

	"$@" >&2

	if [[ $? -gt 0 ]] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" failed." >&2
		return 1
	fi

	echo -n .
}

# Expect failure {{{1
################################################################

function expect_failure {

	local cmd="$*"

	"$@" >&2

	if [ $? -eq 0 ] ; then
		print_call_stack >&2
		echo "Command \"$cmd\" was successful, but expected failure." >&2
		return 1
	fi

	echo -n .
}

# Expect string null {{{1
################################################################

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

# Expect defined env var {{{1
################################################################

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

# Expect string not null {{{1
################################################################

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

# Expect string equal {{{1
################################################################

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

# Expect string regexp {{{1
################################################################

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

# Expect numeric equal {{{1
################################################################

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

# Expect numeric not equal {{{1
################################################################

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

# Expect numeric lower or equal {{{1
################################################################

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

# Expect numeric greater than {{{1
################################################################

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

# Expect no path {{{1
################################################################

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

# Expect folder {{{1
################################################################

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

# Expect non empty file {{{1
################################################################

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

# Expect file {{{1
################################################################

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

# Deprecated
function expect_file_exists {
	expect_file "$@"
}

# Expect other files in folder {{{1
################################################################

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

# Expect other files in tree {{{1
################################################################

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

# Expect no other files in tree {{{1
################################################################

function expect_no_other_files_in_tree {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	files_matching=$(find "$folder" -type f -printf '"%p"\n' | xargs -n 1 basename | egrep "$files_regex")
	files_not_matching=$(find "$folder" -type f -printf '"%p"\n' | xargs -n 1 basename | egrep -v "$files_regex")
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

# Expect no other files in folder {{{1
################################################################

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

# Expect files in tree {{{1
################################################################

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
# Expect files in folder {{{1
################################################################

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

# Expect same files {{{1
################################################################

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

# Expect same folders {{{1
################################################################

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

# CSV expect not has columns {{{1
################################################################

function csv_expect_not_has_columns {

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

# CSV expect has columns {{{1
################################################################

function csv_expect_has_columns {

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

# Expect same number of rows {{{1
################################################################

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

# CSV expect identical column values {{{1
################################################################

function csv_expect_identical_col_values {

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

# CSV expect same col_names {{{1
################################################################

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

# CSV expect float column equals {{{1
################################################################

function csv_expect_float_col_equals {

	local file=$1
	local sep=$2
	local col=$3
	local val=$4
	local tol=$5

	col_index=$(csv_get_col_index $file $sep $col)
	ident=$(awk 'function abs(v) { return v < 0 ? -v : v }BEGIN{FS="'$sep'";eq=1}{if (NR > 1 && abs($'$col_index' - '$val') > '$tol') {eq=0}}END{print eq}' $file)

	[[ $ident -eq 1 ]] || return 1
}

# Expect no duplicated row {{{1
################################################################

function expect_no_duplicated_row {

	local file=$1

	nrows=$(cat $file | wc -l)
	n_uniq_rows=$(sort -u $file | wc -l)
	[[ $nrows -eq $n_uniq_rows ]] || return 1
}

# Main {{{1
################################################################

# Read arguments
read_args "$@"

# Loop on folders and files to test
for e in ${TOTEST[@]} ; do

	[[ -f $e || -d $e ]] || error "\"$e\" is neither a file nor a folder."

	# File
	[[ -f $e ]] && run_test_file "$e"

	# Folder
	if [[ -d $e ]] ; then
		tmp_file=$(mktemp -t $PROGNAME.XXXXXX)
		ls $e/* | sort >$tmp_file
		while read f ; do
			[[ -f $f && $f =~ ^[^/]*/$FILE_PATTERN$ ]] && run_test_file "$f"
		done <$tmp_file
	fi

done

# Finalize
finalize_tests
