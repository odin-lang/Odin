package test_issue_integer_literal_exponent

// A character that is not a digit in the exponent of an integer literal used to be ignored, so `1e1f`
// was accepted as 10.

valid   :: 1e3
invalid :: 1e1f // Error
