# vi: se fdm=marker

# Test numeric testing {{{1
################################################################

function test_numeric_testing {
	expect_failure expect_num_ne 0 0 "Message" || return 1
	expect_failure expect_num_ne 5 5 "Message" || return 1
	expect_success expect_num_ne 0 1 "Message" || return 1

	expect_success expect_num_eq 0 0 "Message" || return 1
	expect_success expect_num_eq 5 5 "Message" || return 1
	expect_failure expect_num_eq 0 1 "Message" || return 1

	expect_success expect_num_le 0 0 "Message" || return 1
	expect_success expect_num_le 0 1 "Message" || return 1
	expect_success expect_num_le 1 10 "Message" || return 1
	expect_success expect_num_le 10 10 "Message" || return 1
	expect_failure expect_num_le 1 0 "Message" || return 1

	expect_success expect_num_gt 1 0 "Message" || return 1
	expect_failure expect_num_gt 0 1 "Message" || return 1
	expect_failure expect_num_gt 0 0 "Message" || return 1
}

# Test string testing {{{1
################################################################

function test_string_testing {
	expect_failure expect_str_null "blabla" "Message" || return 1
	expect_success expect_str_null "" "Message" || return 1
	expect_failure expect_str_not_null "" "Message" || return 1
	expect_success expect_str_not_null "blabla" "Message" || return 1
}

# Test file system testing {{{1
################################################################

function test_file_system_testing {

	# File
	expect_failure expect_file "a_file_that_does_not_exist" "Message" || return 1
	expect_failure expect_file_exists "a_file_that_does_not_exist" "Message" || return 1
	touch "a_file"
	expect_success expect_file "a_file" "Message" || return 1
	expect_success expect_file_exists "a_file" "Message" || return 1
	expect_failure expect_non_empty_file "a_file" "Message" || return 1
	echo "Some content" > "a_file"
	expect_success expect_non_empty_file "a_file" "Message" || return 1
	rm "a_file"

	# Folder
	expect_failure expect_folder "a_folder_that_does_not_exist" "Message" || return 1
	mkdir "a_folder"
	expect_success expect_folder "a_folder" "Message" || return 1
	rmdir "a_folder"

	# Files in folder
	mkdir "a_folder"
	touch "a_folder/a.txt"
	expect_success expect_files_in_folder "a_folder" '^.*\.txt$' "Message" || return 1
	expect_failure expect_files_in_folder "a_folder" '^.*\.csv$' "Message" || return 1
	rm -r "a_folder"

	# Other files in folder
	mkdir "a_folder"
	touch "a_folder/a.txt"
	expect_success expect_files_in_folder "a_folder" '^.*\.txt$' "Message" || return 1
	expect_success expect_no_other_files_in_folder "a_folder" '^.*\.txt$' "Message" || return 1
	touch "a_folder/a.csv"
	expect_success expect_files_in_folder "a_folder" '^.*\.csv$' "Message" || return 1
	expect_success expect_other_files_in_folder "a_folder" '^.*\.txt$' "Message" || return 1
	expect_failure expect_no_other_files_in_folder "a_folder" '^.*\.txt$' "Message" || return 1
	rm -r "a_folder"

	# Other files in tree
	mkdir -p "a_folder/and_its_subfolder"
	expect_failure expect_files_in_tree "a_folder" '^.*\.t.*$' "Message" || return 1
	touch "a_folder/a.txt"
	touch "a_folder/and_its_subfolder/another_file.txt"
	touch "a_folder/and_its_subfolder/another_file.tsv"
	expect_success expect_files_in_tree "a_folder" '^.*\.t.*$' "Message" || return 1
	expect_success expect_files_in_tree "a_folder" '^.*\.txt$' "Message" || return 1
	expect_success expect_no_other_files_in_tree "a_folder" '^.*\.t.*$' "Message" || return 1
	expect_failure expect_other_files_in_tree "a_folder" '^.*\.t.*$' "Message" || return 1
	expect_failure expect_files_in_tree "a_folder" '^.*\.csv$' "Message" || return 1
	touch "a_folder/and_its_subfolder/another_file.csv"
	expect_failure expect_no_other_files_in_tree "a_folder" '^.*\.t.*$' "Message" || return 1
	expect_success expect_other_files_in_tree "a_folder" '^.*\.t.*$' "Message" || return 1
	rm -r "a_folder"
}

# MAIN {{{1
################################################################

test_context "Testing testthat"

test_that "Numeric testing works well." test_numeric_testing
test_that "String testing works well." test_string_testing
test_that "File system testing works well." test_file_system_testing
