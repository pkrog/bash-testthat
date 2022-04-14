test_context "Testing file system assertions"

TEST_DIR=$(dirname $BASH_SOURCE)
WORK_DIR="$TEST_DIR/workspace"
mkdir -p "$WORK_DIR"

function test_expect_file {

	local file="$WORK_DIR/afile"
	rm -f "$file"

	expect_failure expect_file "a_file_that_does_not_exist" "Message" || return 1
	expect_failure expect_file_exists "a_file_that_does_not_exist" "Message" || return 1
	expect_failure expect_file "$file" "Message" || return 1
	touch "$file"
	expect_success expect_file "$file" "Message" || return 1
	expect_success expect_file_exists "$file" "Message" || return 1
	expect_failure expect_non_empty_file "$file" "Message" || return 1
	echo "Some content" > "$file"
	expect_success expect_non_empty_file "$file" "Message" || return 1
	rm "$file"
	expect_failure expect_file "$file" "Message" || return 1
}

function test_expect_symlink {

	local file="$WORK_DIR/afile"
	local symlink="$WORK_DIR/asymkink"
	rm -f "$symlink" "$file"

	expect_failure expect_symlink "$symlink" "$file" "Message" || return 1
	expect_failure expect_symlink "a_symlink_that_does_not_exist" "a_file_that_does_not_exist" "Message" || return 1
	touch "$file"
	expect_success expect_file "$file" "Message" || return 1
	expect_failure expect_symlink "file" "a_file_that_does_not_exist" "Message" || return 1
	ln -sf $(realpath "$file") "$symlink"
	expect_failure expect_symlink "$symlink" "a_file_that_does_not_exist" "Message" || return 1
	expect_success expect_symlink "$symlink" "$file" "Message" || return 1
	rm "$symlink"
	rm "$file"
}

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

function test_expect_folder_is_writable {

	local folder="$WORK_DIR/afolder"
	rm -r "$folder"
	mkdir -p "$folder"
	chmod a-w "$folder"
	expect_failure expect_folder_is_writable "$folder" "Message" "" return 1
	chmod u+w "$folder"
	expect_success expect_folder_is_writable "$folder" "Message" "" return 1
}

function test_expect_files_in_folder {
	local folder="$WORK_DIR/afolder"
	local file="$folder/afile.txt"

	rm -rf "$folder"
	mkdir "$folder"
	touch "$file"
	expect_success expect_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
	expect_failure expect_files_in_folder "$folder" '^.*\.csv$' "Message" || return 1
	rm -r "$folder"
}

function test_expect_no_other_files_in_folder {
	local folder="$WORK_DIR/afolder"
	local file="$folder/afile.txt"

	rm -rf "$folder"
	mkdir "$folder"
	touch "$file"
	expect_success expect_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
	expect_success expect_no_other_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
}

function test_expect_other_files_in_folder {
	local folder="$WORK_DIR/afolder"
	local file1="$folder/afile.txt"
	local file2="$folder/afile.csv"

	rm -rf "$folder"
	mkdir "$folder"
	touch "$file1"
	touch "$file2"
	expect_success expect_files_in_folder "$folder" '^.*\.csv$' "Message" || return 1
	expect_success expect_other_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
	expect_failure expect_no_other_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
}

function test_expect_files_in_tree {
	local folder="$WORK_DIR/afolder"
	local subfolder="$WORK_DIR/afolder/and_its_subfolder"

	rm -rf "$folder"
	mkdir -p "$subfolder"
	expect_failure expect_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	touch "$folder/a.txt"
	touch "$subfolder/another_file.txt"
	touch "$subfolder/another_file.tsv"
	expect_success expect_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	expect_success expect_files_in_tree "$folder" '^.*\.txt$' "Message" || return 1
	expect_success expect_files_in_tree "$folder" '^.*\.tsv$' "Message" || return 1
	expect_failure expect_files_in_tree "$folder" '^.*\.csv$' "Message" || return 1
}

function test_expect_no_other_files_in_tree {
	local folder="$WORK_DIR/afolder"
	local subfolder="$WORK_DIR/afolder/and_its_subfolder"

	rm -rf "$folder"
	mkdir -p "$subfolder"
	expect_failure expect_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	expect_failure expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	touch "$folder/a.txt"
	expect_success expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	expect_failure expect_no_other_files_in_tree "$folder" '^.*\.c.*$' "Message" || return 1
	touch "$subfolder/another_file.txt"
	touch "$subfolder/another_file.tsv"
	expect_success expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	expect_failure expect_no_other_files_in_tree "$folder" '^.*\.c.*$' "Message" || return 1
}

function test_expect_other_files_in_tree {
	local folder="$WORK_DIR/afolder"
	local subfolder="$WORK_DIR/afolder/and_its_subfolder"

	rm -rf "$folder"
	mkdir -p "$subfolder"
	touch "$folder/a.txt"
	touch "$subfolder/another_file.txt"
	touch "$subfolder/another_file.tsv"
	expect_success expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	expect_failure expect_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	expect_failure expect_files_in_tree "$folder" '^.*\.csv$' "Message" || return 1
	touch "$subfolder/another_file.csv"
	expect_failure expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	expect_success expect_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
}

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

function test_expect_output_nlines_eq {

	expect_success expect_output_nlines_eq 0 echo -n "" || return 1
	expect_failure expect_output_nlines_eq 1 echo -n "" || return 1
	expect_failure expect_output_nlines_eq 0 echo "" || return 1
	expect_success expect_output_nlines_eq 1 echo "" || return 1
	expect_failure expect_output_nlines_eq 0 echo -n "ABC" || return 1
	expect_success expect_output_nlines_eq 1 echo -n "ABC" || return 1
	expect_failure expect_output_nlines_eq 2 echo -n "ABC" || return 1
	expect_failure expect_output_nlines_eq 0 echo "ABC" || return 1
	expect_success expect_output_nlines_eq 1 echo "ABC" || return 1
	expect_failure expect_output_nlines_eq 2 echo "ABC" || return 1
	expect_failure expect_output_nlines_eq 0 echo -en "ABC\nDEF" || return 1
	expect_failure expect_output_nlines_eq 1 echo -en "ABC\nDEF" || return 1
	expect_success expect_output_nlines_eq 2 echo -en "ABC\nDEF" || return 1
	expect_failure expect_output_nlines_eq 3 echo -en "ABC\nDEF" || return 1
	expect_failure expect_output_nlines_eq 0 echo -e "ABC\nDEF" || return 1
	expect_failure expect_output_nlines_eq 1 echo -e "ABC\nDEF" || return 1
	expect_success expect_output_nlines_eq 2 echo -e "ABC\nDEF" || return 1
	expect_failure expect_output_nlines_eq 3 echo -e "ABC\nDEF" || return 1
}
