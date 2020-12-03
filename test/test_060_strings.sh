test_context "Testing string assertions"

function test_expect_str_null {
	expect_failure expect_str_null "blabla" "Message" || return 1
	expect_success expect_str_null "" "Message" || return 1
}

function test_expect_str_not_null {
	expect_failure expect_str_not_null "" || return 1
	expect_failure expect_str_not_null "" "Message" || return 1
	expect_success expect_str_not_null "blabla" || return 1
	expect_success expect_str_not_null "blabla" "Message" || return 1
}

function test_expect_str_eq {
	expect_failure expect_str_eq "a" "" || return 1
	expect_failure expect_str_eq "" "b" || return 1
	expect_failure expect_str_eq "a" "b" || return 1
	expect_failure expect_str_eq "a" "b" "Message" || return 1
	expect_success expect_str_eq "" "" || return 1
	expect_success expect_str_eq "a" "a" || return 1
	expect_success expect_str_eq "a" "a" "Message" || return 1
	expect_success expect_str_eq "a b" "a b" || return 1
	expect_success expect_str_eq "a b" "a b" "Message" || return 1
}

function test_expect_str_ne {
	expect_failure expect_str_ne "" "" || return 1
	expect_failure expect_str_ne "a" "a" || return 1
	expect_failure expect_str_ne "a" "a" "Message" || return 1
	expect_success expect_str_ne "a" "b" || return 1
	expect_success expect_str_ne "a" "b" "Message" || return 1
	expect_success expect_str_ne "a b" "a c" || return 1
	expect_success expect_str_ne "a b" "a c" "Message" || return 1
}
