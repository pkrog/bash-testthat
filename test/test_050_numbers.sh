test_context "Testing numeric assertions"

function test_expect_num_ne {
	expect_failure expect_num_ne 0 0 "Message" || return 1
	expect_failure expect_num_ne 5 5 "Message" || return 1
	expect_success expect_num_ne 0 1 "Message" || return 1
}

function test_expect_num_eq {
	expect_success expect_num_eq 0 0 "Message" || return 1
	expect_success expect_num_eq 5 5 "Message" || return 1
	expect_failure expect_num_eq 0 1 "Message" || return 1
}

function test_expect_num_le {
	expect_success expect_num_le 0 0 "Message" || return 1
	expect_success expect_num_le 0 1 "Message" || return 1
	expect_success expect_num_le 1 10 "Message" || return 1
	expect_success expect_num_le 10 10 "Message" || return 1
	expect_failure expect_num_le 1 0 "Message" || return 1
}

function test_expect_num_gt {
	expect_success expect_num_gt 1 0 "Message" || return 1
	expect_failure expect_num_gt 0 1 "Message" || return 1
	expect_failure expect_num_gt 0 0 "Message" || return 1
}
