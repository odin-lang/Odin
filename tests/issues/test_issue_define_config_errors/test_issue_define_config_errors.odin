package test_issue_define_config_errors

E :: enum { A, B }

Flags :: bit_set[E]

NOT_A_NUMBER  :: #config(DEFINE_NOT_A_NUMBER, 0)
OUT_OF_RANGE  :: #config(DEFINE_OUT_OF_RANGE, u8(0))
TRUNCATED     :: #config(DEFINE_TRUNCATED, 0)
NOT_A_BOOL    :: #config(DEFINE_NOT_A_BOOL, false)
EMPTY_BOOL    :: #config(DEFINE_EMPTY, false)
NOT_A_FIELD   :: #config(DEFINE_NOT_A_FIELD, E.A)
NOT_SETTABLE  :: #config(DEFINE_NOT_SETTABLE, Flags{})
QUOTED_NUMBER :: #config(DEFINE_QUOTED_NUMBER, 0)
