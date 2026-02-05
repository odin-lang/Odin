package bifrost_http

H2_PREFACE :: "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"

H2_Frame_Type :: enum u8 {
	Data          = 0x0,
	Headers       = 0x1,
	Priority      = 0x2,
	RST_Stream    = 0x3,
	Settings      = 0x4,
	Push_Promise  = 0x5,
	Ping          = 0x6,
	GoAway        = 0x7,
	Window_Update = 0x8,
	Continuation  = 0x9,
}

H2_FLAG_END_STREAM  :: u8(0x1)
H2_FLAG_END_HEADERS :: u8(0x4)
H2_FLAG_PADDED      :: u8(0x8)
H2_FLAG_PRIORITY    :: u8(0x20)
H2_FLAG_ACK         :: u8(0x1)

H2_Error_Code :: enum u32 {
	No_Error             = 0x0,
	Protocol_Error       = 0x1,
	Internal_Error       = 0x2,
	Flow_Control_Error   = 0x3,
	Settings_Timeout     = 0x4,
	Stream_Closed        = 0x5,
	Frame_Size_Error     = 0x6,
	Refused_Stream       = 0x7,
	Cancel               = 0x8,
	Compression_Error    = 0x9,
	Connect_Error        = 0xa,
	Enhance_Your_Calm    = 0xb,
	Inadequate_Security  = 0xc,
	HTTP_1_1_Required    = 0xd,
}

h2_error_string :: proc(code: H2_Error_Code) -> string {
	switch code {
	case .No_Error:            return "NO_ERROR"
	case .Protocol_Error:      return "PROTOCOL_ERROR"
	case .Internal_Error:      return "INTERNAL_ERROR"
	case .Flow_Control_Error:  return "FLOW_CONTROL_ERROR"
	case .Settings_Timeout:    return "SETTINGS_TIMEOUT"
	case .Stream_Closed:       return "STREAM_CLOSED"
	case .Frame_Size_Error:    return "FRAME_SIZE_ERROR"
	case .Refused_Stream:      return "REFUSED_STREAM"
	case .Cancel:              return "CANCEL"
	case .Compression_Error:   return "COMPRESSION_ERROR"
	case .Connect_Error:       return "CONNECT_ERROR"
	case .Enhance_Your_Calm:   return "ENHANCE_YOUR_CALM"
	case .Inadequate_Security: return "INADEQUATE_SECURITY"
	case .HTTP_1_1_Required:   return "HTTP_1_1_REQUIRED"
	}
	return "UNKNOWN_ERROR"
}

H2_Settings_Id :: enum u16 {
	Header_Table_Size      = 0x1,
	Enable_Push            = 0x2,
	Max_Concurrent_Streams = 0x3,
	Initial_Window_Size    = 0x4,
	Max_Frame_Size         = 0x5,
	Max_Header_List_Size   = 0x6,
}

H2_Settings :: struct {
	Header_Table_Size: u32,
	Enable_Push: bool,
	Max_Concurrent_Streams: u32,
	Initial_Window_Size: u32,
	Max_Frame_Size: u32,
	Max_Header_List_Size: u32,
}

h2_settings_default :: proc() -> H2_Settings {
	return H2_Settings{
		Header_Table_Size = 4096,
		Enable_Push = true,
		Max_Concurrent_Streams = 0,
		Initial_Window_Size = 65535,
		Max_Frame_Size = 16384,
		Max_Header_List_Size = 0,
	}
}
