package noise

import "core:slice"

@(private)
Pre_Token :: enum {
	res_s,
	ini_s,
}

@(private)
Token :: enum {
	e,
	s,
	ee,
	es,
	se,
	ss,
	psk,
}

@(private)
Message_Pattern :: struct {
	pre_messages: []Pre_Token,
	messages: [][]Token,
	is_psk: bool,
	is_one_way: bool,
}

// Handshake_Pattern is the list of currently supported Noise Handshake
// Patterns.
Handshake_Pattern :: enum {
	Invalid,

	// One way patterns
	N,
	K,
	X,

	// Fundamental patterns
	XX,
	NK,
	NN,
	KN,
	KK,
	NX,
	KX,
	XN,
	IN,
	XK,
	IK,
	IX,

	// Recommended PSK patterns
	Npsk0,
	Kpsk0,
	Xpsk1,
	NNpsk0,
	NNpsk2,
	NKpsk0,
	NKpsk2,
	NXpsk2,
	XNpsk3,
	XKpsk3,
	XXpsk3,
	KNpsk0,
	KNpsk2,
	KKpsk0,
	KKpsk2,
	KXpsk2,
	INpsk1,
	INpsk2,
	IKpsk1,
	IKpsk2,
	IXpsk2,
}

pattern_requires_initiator_s :: proc(pattern: Handshake_Pattern) -> (pre: bool, hs: bool) {
	p := HANDSHAKE_PATTERNS[pattern]
	if slice.contains(p.pre_messages, Pre_Token.ini_s) {
		pre = true
	}
	for msg, i in p.messages {
		if i & 1 != 0 {
			continue
		}
		if slice.contains(msg, Token.s) {
			hs = true
			break
		}
	}
	return pre, hs
}

pattern_requires_responder_s :: proc(pattern: Handshake_Pattern) -> (pre: bool, hs: bool) {
	p := HANDSHAKE_PATTERNS[pattern]
	if slice.contains(p.pre_messages, Pre_Token.res_s) {
		pre = true
	}
	for msg, i in p.messages {
		if i & 1 == 0 {
			continue
		}
		if slice.contains(msg, Token.s) {
			hs = true
			break
		}
	}
	return pre, hs
}

pattern_is_psk :: proc(pattern: Handshake_Pattern) -> bool {
	return HANDSHAKE_PATTERNS[pattern].is_psk
}

pattern_is_one_way :: proc(pattern: Handshake_Pattern) -> bool {
	return HANDSHAKE_PATTERNS[pattern].is_one_way
}

@(private)
HANDSHAKE_PATTERNS := [Handshake_Pattern]^Message_Pattern {
	.Invalid = nil,
	.N = &PATTERN_N,
	.K = &PATTERN_K,
	.X = &PATTERN_X,
	.XX = &PATTERN_XX,
	.NK = &PATTERN_NK,
	.NN = &PATTERN_NN,
	.KN = &PATTERN_KN,
	.KK = &PATTERN_KK,
	.NX = &PATTERN_NX,
	.KX = &PATTERN_KX,
	.XN = &PATTERN_XN,
	.IN = &PATTERN_IN,
	.XK = &PATTERN_XK,
	.IK = &PATTERN_IK,
	.IX = &PATTERN_IX,
	.Npsk0 = &PATTERN_Npsk0,
	.Kpsk0 = &PATTERN_Kpsk0,
	.Xpsk1 = &PATTERN_Xpsk1,
	.NNpsk0 = &PATTERN_NNpsk0,
	.NNpsk2 = &PATTERN_NNpsk2,
	.NKpsk0 = &PATTERN_NKpsk0,
	.NKpsk2 = &PATTERN_NKpsk2,
	.NXpsk2 = &PATTERN_NXpsk2,
	.XNpsk3 = &PATTERN_XNpsk3,
	.XKpsk3 = &PATTERN_XKpsk3,
	.XXpsk3 = &PATTERN_XXpsk3,
	.KNpsk0 = &PATTERN_KNpsk0,
	.KNpsk2 = &PATTERN_KNpsk2,
	.KKpsk0 = &PATTERN_KKpsk0,
	.KKpsk2 = &PATTERN_KKpsk2,
	.KXpsk2 = &PATTERN_KXpsk2,
	.INpsk1 = &PATTERN_INpsk1,
	.INpsk2 = &PATTERN_INpsk2,
	.IKpsk1 = &PATTERN_IKpsk1,
	.IKpsk2 = &PATTERN_IKpsk2,
	.IXpsk2 = &PATTERN_IXpsk2,
}

// ------------- ONE WAY PATTERNS ---------------------------------------------------------

// N:
//   <- s
//   ...
//   -> e, es
@(private,rodata)
PATTERN_N : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es},
	},
	is_one_way = true,
}

// K:
//   -> s
//   <- s
//   ...
//   -> e, es, ss
@(private,rodata)
PATTERN_K : Message_Pattern = {
	pre_messages = {.ini_s, .res_s},
	messages = {
		{.e, .es, .ss},
	},
	is_one_way = true,
}

// X:
//   <- s
//   ...
//   -> e, es, s, ss
@(private,rodata)
PATTERN_X : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es, .s, .ss},
	},
	is_one_way = true,
}

// ----------------------------------------------------------------------------------------

// ------------- FUNDAMENTAL PATTERNS -----------------------------------------------------

// XX:
//   -> e
//   <- e, ee, s, es
//   -> s, se
@(private,rodata)
PATTERN_XX : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee, .s, .es},
		{.s, .se},
	},
}

// NK:
//   <- s
//   ...
//   -> e, es
//   <- e, ee
@(private,rodata)
PATTERN_NK : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es},
		{.e, .ee},
	},
}

// NN:
//   -> e
//   <- e, ee
@(private,rodata)
PATTERN_NN : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee},
	},
}

// KN:
//   -> s
//   ...
//   -> e
//   <- e, ee, se
@(private,rodata)
PATTERN_KN : Message_Pattern = {
	pre_messages = {.ini_s},
	messages = {
		{.e,},
		{.e, .ee, .se},
	},
}

// KK:
//   -> s
//   <- s
//   ...
//   -> e, es, ss
//   <- e, ee, se
@(private,rodata)
PATTERN_KK : Message_Pattern = {
	pre_messages = {.ini_s, .res_s},
	messages = {
		{.e, .es, .ss},
		{.e, .ee, .se},
	},
}

// NX:
//   -> e
//   <- e, ee, s, es
@(private,rodata)
PATTERN_NX : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee, .s, .es},
	},
}

// KX:
//   -> s
//   ...
//   -> e
//   <- e, ee, se, s, es
@(private,rodata)
PATTERN_KX : Message_Pattern = {
	pre_messages = {.ini_s},
	messages = {
		{.e},
		{.e, .ee, .se, .s, .es},
	},
}

// XN:
//   -> e
//   <- e, ee
//   -> s, se
@(private,rodata)
PATTERN_XN : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee},
		{.s, .se},
	},
}

// IN:
//   -> e, s
//   <- e, ee, se
@(private,rodata)
PATTERN_IN : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e, .s},
		{.e, .ee, .se},
	},
}

// XK:
//   <- s
//   ...
//   -> e, es
//   <- e, ee
//   -> s, se
@(private,rodata)
PATTERN_XK : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es},
		{.e, .ee},
		{.s, .se},
	},
}

// IK:
//   <- s
//   ...
//   -> e, es, s, ss
//   <- e, ee, se
@(private,rodata)
PATTERN_IK : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es, .s, .ss},
		{.e, .ee, .se},
	},
}

// IX:
//   -> e, s
//   <- e, ee, se, s, es
@(private,rodata)
PATTERN_IX :  Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e, .s},
		{.e, .ee, .se, .s, .es},
	},
}

// ----------------------------------------------------------------------------------------

// ------------- PSK PATTERNS -------------------------------------------------------------

// Npsk0:
//   <- s
//   ...
//   -> psk, e, es
@(private,rodata)
PATTERN_Npsk0 : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.psk, .e, .es},
	},
	is_psk = true,
	is_one_way = true,
}

// K:
//   -> s
//   <- s
//   ...
//   -> psk, e, es, ss
@(private,rodata)
PATTERN_Kpsk0 : Message_Pattern = {
	pre_messages = {.ini_s, .res_s},
	messages = {
		{.psk, .e, .es, .ss},
	},
	is_psk = true,
	is_one_way = true,
}

// X:
//   <- s
//   ...
//   -> e, es, s, ss, psk
@(private,rodata)
PATTERN_Xpsk1 : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es, .s, .ss, .psk},
	},
	is_psk = true,
	is_one_way = true,
}

// NNpsk0:
//   -> psk, e
//   <- e, ee
@(private,rodata)
PATTERN_NNpsk0 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.psk, .e},
		{.e, .ee},
	},
	is_psk = true,
}

// NNpsk2:
//   -> e
//   <- e, ee, psk
@(private,rodata)
PATTERN_NNpsk2 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee, .psk},
	},
	is_psk = true,
}

// NKpsk0:
//   <- s
//   ...
//   -> psk, e, es
//   <- e, ee
@(private,rodata)
PATTERN_NKpsk0 : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.psk, .e, .es},
		{.e, .ee},
	},
	is_psk = true,
}

// NKpsk2:
//   <- s
//   ...
//   -> e, es
//   <- e, ee, psk
@(private,rodata)
PATTERN_NKpsk2 : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es},
		{.e, .ee, .psk},
	},
	is_psk = true,
}

//  NXpsk2:
//	-> e
//	<- e, ee, s, es, psk
@(private,rodata)
PATTERN_NXpsk2 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee, .s, .es, .psk},
	},
	is_psk = true,
}

//  XNpsk3:
//	-> e
//	<- e, ee
//	-> s, se, psk
@(private,rodata)
PATTERN_XNpsk3 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee},
		{.s, .se, .psk},
	},
	is_psk = true,
}

//  XKpsk3:
//	<- s
//	...
//	-> e, es
//	<- e, ee
//	-> s, se, psk
@(private,rodata)
PATTERN_XKpsk3 : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es},
		{.e, .ee},
		{.s, .se, .psk},
	},
	is_psk = true,
}

//  XXpsk3:
//	-> e
//	<- e, ee, s, es
//	-> s, se, psk
@(private,rodata)
PATTERN_XXpsk3 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e},
		{.e, .ee, .s, .es},
		{.s, .se, .psk},
	},
	is_psk = true,
}

//   KNpsk0:
//	 -> s
//	 ...
//	 -> psk, e
//	 <- e, ee, se
@(private,rodata)
PATTERN_KNpsk0 : Message_Pattern = {
	pre_messages = {.ini_s},
	messages = {
		{.psk, .e},
		{.e, .ee, .se},
	},
	is_psk = true,
}

//   KNpsk2:
//	 -> s
//	 ...
//	 -> e
//	 <- e, ee, se, psk
@(private,rodata)
PATTERN_KNpsk2 : Message_Pattern = {
	pre_messages = {.ini_s},
	messages = {
		{.e},
		{.e, .ee, .se, .psk},
	},
	is_psk = true,
}

//   KKpsk0:
//	 -> s
//	 <- s
//	 ...
//	 -> psk, e, es, ss
//	 <- e, ee, se
@(private,rodata)
PATTERN_KKpsk0 : Message_Pattern = {
	pre_messages = {.ini_s, .res_s},
	messages = {
		{.psk, .e, .es, .ss},
		{.e, .ee, .se},
	},
	is_psk = true,
}

//   KKpsk2:
//	 -> s
//	 <- s
//	 ...
//	 -> e, es, ss
//	 <- e, ee, se, psk
@(private,rodata)
PATTERN_KKpsk2 : Message_Pattern = {
	pre_messages = {.ini_s, .res_s},
	messages = {
		{.e, .es, .ss},
		{.e, .ee, .se, .psk},
	},
	is_psk = true,
}

//	KXpsk2:
//	  -> s
//	  ...
//	  -> e
//	  <- e, ee, se, s, es, psk
@(private,rodata)
PATTERN_KXpsk2 : Message_Pattern = {
	pre_messages = {.ini_s},
	messages = {
		{.e},
		{.e, .ee, .se, .s, .es, .psk},
	},
	is_psk = true,
}

//	INpsk1:
//	  -> e, s, psk
//	  <- e, ee, se
@(private,rodata)
PATTERN_INpsk1 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e, .s, .psk},
		{.e, .ee, .se},
	},
	is_psk = true,
}

//	INpsk2:
//	  -> e, s
//	  <- e, ee, se, psk
@(private,rodata)
PATTERN_INpsk2 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e, .s},
		{.e, .ee, .se, .psk},
	},
	is_psk = true,
}

//	IKpsk1:
//	  <- s
//	  ...
//	  -> e, es, s, ss, psk
//	  <- e, ee, se
@(private,rodata)
PATTERN_IKpsk1 : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es, .s, .ss, .psk},
		{.e, .ee, .se},
	},
	is_psk = true,
}

//	IKpsk2:
//	  <- s
//	  ...
//	  -> e, es, s, ss
//	  <- e, ee, se, psk
@(private,rodata)
PATTERN_IKpsk2 : Message_Pattern = {
	pre_messages = {.res_s},
	messages = {
		{.e, .es, .s, .ss},
		{.e, .ee, .se, .psk},
	},
	is_psk = true,
}

//	IXpsk2:
//	  -> e, s
//	  <- e, ee, se, s, es, psk
@(private,rodata)
PATTERN_IXpsk2 : Message_Pattern = {
	pre_messages = nil,
	messages = {
		{.e, .s},
		{.e, .ee, .se, .s, .es, .psk},
	},
	is_psk = true,
}
