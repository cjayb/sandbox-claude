#!/usr/bin/env bats
load '../test_helper/common'

@test "parse_issue_spec: full GitHub issues URL" {
  run parse_issue_spec "https://github.com/me/alpha/issues/42"
  assert_success
  assert_output "me/alpha 42"
}

@test "parse_issue_spec: full URL with trailing slash" {
  run parse_issue_spec "https://github.com/me/alpha/issues/42/"
  assert_success
  assert_output "me/alpha 42"
}

@test "parse_issue_spec: full URL with #anchor" {
  run parse_issue_spec "https://github.com/me/alpha/issues/42#issuecomment-1"
  assert_success
  assert_output "me/alpha 42"
}

@test "parse_issue_spec: shorthand owner/repo#N" {
  run parse_issue_spec "me/alpha#42"
  assert_success
  assert_output "me/alpha 42"
}

@test "parse_issue_spec: shorthand with hyphenated names" {
  run parse_issue_spec "my-org/my-repo#1234"
  assert_success
  assert_output "my-org/my-repo 1234"
}

@test "parse_issue_spec: bare #N resolves to cwd repo" {
  cd "$TEST_TMPDIR"
  git init -q
  git remote add origin "git@github.com:me/alpha.git"
  run parse_issue_spec "#42"
  assert_success
  assert_output "me/alpha 42"
}

@test "parse_issue_spec: bare N (no hash) resolves to cwd repo" {
  cd "$TEST_TMPDIR"
  git init -q
  git remote add origin "https://github.com/me/alpha.git"
  run parse_issue_spec "42"
  assert_success
  assert_output "me/alpha 42"
}

@test "parse_issue_spec: bare #N fails outside a git repo" {
  cd "$TEST_TMPDIR"
  run parse_issue_spec "#42"
  assert_failure
  assert_output --partial "requires a git repo"
}

@test "parse_issue_spec: rejects PR URL (issues only)" {
  run parse_issue_spec "https://github.com/me/alpha/pull/42"
  assert_failure
  assert_output --partial "Unrecognized issue spec"
}

@test "parse_issue_spec: rejects garbage" {
  run parse_issue_spec "not-a-spec"
  assert_failure
  assert_output --partial "Unrecognized issue spec"
}
