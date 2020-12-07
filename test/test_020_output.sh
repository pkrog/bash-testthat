test_context "Testing output assertions"

function test_empty_output {
	expect_success expect_empty_output echo -n || return 1
	expect_failure expect_empty_output echo ABC || return 1
}

function test_non_empty_output {
	expect_success expect_non_empty_output echo ABC || return 1
	expect_failure expect_non_empty_output echo -n || return 1
}

function test_output {
	expect_success expect_output "" echo -n || return 1
	expect_success expect_output "ABC" echo -n ABC || return 1
	expect_failure expect_output "1" echo -n || return 1
	expect_success expect_output "A\nBC" echo -ne "A\nBC" || return 1
	expect_success expect_output "ABC\n" echo ABC || return 1
	expect_success expect_output "\n" echo || return 1
}

function test_output_nlines_eq {
	expect_success expect_output_nlines_eq 0 echo -n || return 1
	expect_success expect_output_nlines_eq 1 echo ABC || return 1
	expect_success expect_output_nlines_eq 2 echo -e "A\nBC" || return 1
	expect_success expect_output_nlines_eq 3 echo -e "A\nB\nC" || return 1
	expect_failure expect_output_nlines_eq 2 echo ABC || return 1
	expect_failure expect_output_nlines_eq 0 echo ABC || return 1
	expect_failure expect_output_nlines_eq 1 echo -n || return 1
}

function test_output_nlines_ge {
	expect_success expect_output_nlines_ge 0 echo -n || return 1
	expect_failure expect_output_nlines_ge 1 echo -n || return 1
	expect_success expect_output_nlines_ge 1 echo ABC || return 1
	expect_success expect_output_nlines_ge 0 echo ABC || return 1
	expect_success expect_output_nlines_ge 0 echo -e "A\nBC" || return 1
	expect_success expect_output_nlines_ge 1 echo -e "A\nBC" || return 1
	expect_success expect_output_nlines_ge 2 echo -e "A\nBC" || return 1
	expect_success expect_output_nlines_ge 3 echo -e "A\nB\nC" || return 1
	expect_failure expect_output_nlines_ge 2 echo ABC || return 1
	expect_failure expect_output_nlines_ge 3 echo ABC || return 1
	expect_failure expect_output_nlines_ge 3 echo -e "A\nBC" || return 1
	expect_failure expect_output_nlines_ge 4 echo -e "A\nB\nC" || return 1
}
