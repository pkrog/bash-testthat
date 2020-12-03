# vi: se fdm=marker

test_context "Testing file system assertions"

# Constants {{{1
################################################################################

TEST_DIR=$(dirname $BASH_SOURCE)
WORK_DIR="$TEST_DIR/workspace"

# Test expect_folder {{{1
################################################################################

function test_expect_folder {
	local folder="$WORK_DIR/afolder"
	local file="$WORK_DIR/afile"

	rm -r "$folder"
	expect_failure expect_folder "$folder" "Message" || return 1

	mkdir -p "$folder"
	expect_success expect_folder "$folder" "Message" || return 1

	touch "$file"
	expect_failure expect_folder "$file" "Message" || return 1
}

# Test expect_same_folders {{{1
################################################################################

function test_expect_same_folders {
	local folder_a="$WORK_DIR/folder_a"
	local folder_b="$WORK_DIR/folder_b"

	rm -r "$folder_a" "$folder_b"
	expect_failure expect_same_folders  "$folder_a" "$folder_b" || return 1

	mkdir -p "$folder_a"
	expect_failure expect_same_folders  "$folder_a" "$folder_b" || return 1
	expect_failure expect_same_folders  "$folder_b" "$folder_a" || return 1

	mkdir -p "$folder_b"
	expect_success expect_same_folders  "$folder_a" "$folder_b" || return 1

	touch "$folder_a/somefile"
	expect_failure expect_same_folders  "$folder_a" "$folder_b" || return 1

	touch "$folder_b/somefile"
	expect_success expect_same_folders  "$folder_a" "$folder_b" || return 1
}
