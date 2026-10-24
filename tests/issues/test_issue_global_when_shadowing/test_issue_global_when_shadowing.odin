// -vet-when-shadowing, enabled by -vet: a global 'when' declaring a builtin name
package test_issue_global_when_shadowing

when true { uint :: u32 }
when true { @(private="file") byte :: u16 }
when true { not_shadowing :: 1 }
