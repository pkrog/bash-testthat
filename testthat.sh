#!/bin/bash
# vi: fdm=marker

# Constants {{{1
################################################################

PROGNAME=$(basename $0)
VERSION=1.1.0

# Global variables {{{1
################################################################

g_debug=0
g_totest=
g_nb_test_context=0
g_err_number=0
declare -a g_err_msgs=()
declare -a g_err_output_files=()

# Print help {{{1
################################################################

function print_help {
	echo "Usage: $PROGNAME [options] <folders or files>"
	echo
	echo "The folders are searched for files matching 'test-*.sh' pattern."
	echo
	echo "Options:"
	echo "   -g, --debug          Debug mode."
	echo "   -h, --help           Print this help message."
	echo "   -v, --version        Print version."
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

	[ $g_debug -ge $dbglvl ] && echo "[g_debug] $dbgmsg" >&2
}

# Read args {{{1
################################################################

function read_args {

	local args="$*" # save arguments for debugging purpose
	
	# Read options
	while true ; do
		case $1 in
			-g|--debug)         g_debug=$((g_debug + 1)) ;;
			-h|--help)          print_help ; exit 0 ;;
			-v|--version)       echo $VERSION ; exit 0 ;;
			-) error "Illegal option $1." ;;
			--) error "Illegal option $1." ;;
			--*) error "Illegal option $1." ;;
			-?) error "Unknown option $1." ;;
			-[^-]*) split_opt=$(echo $1 | sed 's/^-//' | sed 's/\([a-zA-Z]\)/ -\1/g') ; set -- $1$split_opt "${@:2}" ;;
			*) break
		esac
		shift
	done
	shift $((OPTIND - 1))

	# Read remaining arguments as a list of folders and/or files
	if [ -n "$*" ] ; then
		g_totest=("$@")
	else
		g_totest=()
	fi

	# Debug
	print_debug_msg 1 "Arguments are : $args"
	print_debug_msg 1 "Folders and files to test are : $g_totest"
}

# Test context {{{1
################################################################

function test_context {

	local msg=$1

	[[ $g_nb_test_context -gt 0 ]] && echo

	echo -n "$msg "

	((g_nb_test_context=g_nb_test_context+1))
}

# Test that {{{1
################################################################

function test_that {

	local msg=$1
	local test_fct=$2
	shift 2
	local params="$*"
	local tmp_output_file=$(mktemp -t test-searchmz-output.XXXXXX)

	# Filtering
	if [[ -n $TEST_THAT_FCT && ",$TEST_THAT_FCT," != *",$test_fct,"* ]] ; then
		return 0
	fi

	# Run test
	$test_fct $params 2>$tmp_output_file

	# Failure
	exit_code=$?
	if [ $exit_code -gt 0 ] ; then
		((g_err_number=g_err_number+1))
		if [[ g_err_number -le 16 ]] ; then
			printf %x $g_err_number
		else
			echo -n E
		fi
		g_err_msgs+=("Failure while asserting that \"$msg\".")
		g_err_output_files+=($tmp_output_file)

	# Success
	else
		rm $tmp_output_file
	fi
}

# Test report {{{1
################################################################

function test_report {

	[[ $g_nb_test_context -eq 0 ]] || echo

	if [[ $g_err_number -gt 0 ]] ; then
		echo '================================================================'
		echo "$g_err_number error(s) encountered."

		# Loop on all errors
		for ((i = 0 ; i < g_err_number ; ++i)) ; do
			echo
			printf %x $((i+1))
			echo . ${g_err_msgs[$i]}
			cat ${g_err_output_files[$i]}
			rm ${g_err_output_files[$i]}
			echo '----------------------------------------------------------------'
		done
	fi
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

# Expect success {{{1
################################################################

function expect_success {

	local cmd="$*"

	$cmd >&2

	if [ $? -gt 0 ] ; then
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

	$cmd >&2

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

	if [[ -z $v ]] ; then
		print_call_stack >&2
		echo "String \"$v\" is null ! $msg" >&2
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

	local s=$(echo "$str" | grep "$re")
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
	local msg="$*"

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
	local msg="$*"

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
	local msg="$*"

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
	local msg="$*"

	if [[ ! $a -gt $b ]] ; then
		print_call_stack >&2
		echo "$a > $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

# Expect file exists {{{1
################################################################

function expect_file_exists {

	local file=$1

	if [[ ! -f $file ]] ; then
		print_call_stack >&2
		echo "File \"$file\" does not exist." >&2
		return 1
	fi

	echo -n .
}

# Expect same files {{{1
################################################################

function expect_same_files {

	local file1=$1
	local file2=$2

	if ! diff -q $file1 $file2 ; then
		print_call_stack >&2
		echo "Files \"$file1\" and \"$file2\" differ." >&2
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
for e in ${g_totest[@]} ; do

	[[ -f $e || -d $e ]] || error "\"$e\" is neither a file nor a folder."

	# File
	if [[ -f $e ]] ; then
		source $e
	fi

	# Folder
	if [[ -d $e ]] ; then
		for f in $e ; do
			source $f
		done
	fi

done

# Print report
