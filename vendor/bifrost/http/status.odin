package bifrost_http

// Informational
Status_Continue :: 100
Status_Switching_Protocols :: 101
Status_Processing :: 102
Status_Early_Hints :: 103

// Success
Status_OK :: 200
Status_Created :: 201
Status_Accepted :: 202
Status_Non_Authoritative_Information :: 203
Status_No_Content :: 204
Status_Reset_Content :: 205
Status_Partial_Content :: 206
Status_Multi_Status :: 207
Status_Already_Reported :: 208
Status_IM_Used :: 226

// Redirection
Status_Multiple_Choices :: 300
Status_Moved_Permanently :: 301
Status_Found :: 302
Status_See_Other :: 303
Status_Not_Modified :: 304
Status_Use_Proxy :: 305
Status_Temporary_Redirect :: 307
Status_Permanent_Redirect :: 308

// Client Error
Status_Bad_Request :: 400
Status_Unauthorized :: 401
Status_Payment_Required :: 402
Status_Forbidden :: 403
Status_Not_Found :: 404
Status_Method_Not_Allowed :: 405
Status_Not_Acceptable :: 406
Status_Proxy_Auth_Required :: 407
Status_Request_Timeout :: 408
Status_Conflict :: 409
Status_Gone :: 410
Status_Length_Required :: 411
Status_Precondition_Failed :: 412
Status_Payload_Too_Large :: 413
Status_URI_Too_Long :: 414
Status_Unsupported_Media_Type :: 415
Status_Range_Not_Satisfiable :: 416
Status_Expectation_Failed :: 417
Status_Teapot :: 418
Status_Misdirected_Request :: 421
Status_Unprocessable_Entity :: 422
Status_Locked :: 423
Status_Failed_Dependency :: 424
Status_Too_Early :: 425
Status_Upgrade_Required :: 426
Status_Precondition_Required :: 428
Status_Too_Many_Requests :: 429
Status_Request_Header_Fields_Too_Large :: 431
Status_Unavailable_For_Legal_Reasons :: 451

// Server Error
Status_Internal_Server_Error :: 500
Status_Not_Implemented :: 501
Status_Bad_Gateway :: 502
Status_Service_Unavailable :: 503
Status_Gateway_Timeout :: 504
Status_HTTP_Version_Not_Supported :: 505
Status_Variant_Also_Negotiates :: 506
Status_Insufficient_Storage :: 507
Status_Loop_Detected :: 508
Status_Not_Extended :: 510
Status_Network_Authentication_Required :: 511

Status_Text_Continue :: "Continue"
Status_Text_Switching_Protocols :: "Switching Protocols"
Status_Text_Processing :: "Processing"
Status_Text_Early_Hints :: "Early Hints"

Status_Text_OK :: "OK"
Status_Text_Created :: "Created"
Status_Text_Accepted :: "Accepted"
Status_Text_Non_Authoritative_Information :: "Non-Authoritative Information"
Status_Text_No_Content :: "No Content"
Status_Text_Reset_Content :: "Reset Content"
Status_Text_Partial_Content :: "Partial Content"
Status_Text_Multi_Status :: "Multi-Status"
Status_Text_Already_Reported :: "Already Reported"
Status_Text_IM_Used :: "IM Used"

Status_Text_Multiple_Choices :: "Multiple Choices"
Status_Text_Moved_Permanently :: "Moved Permanently"
Status_Text_Found :: "Found"
Status_Text_See_Other :: "See Other"
Status_Text_Not_Modified :: "Not Modified"
Status_Text_Use_Proxy :: "Use Proxy"
Status_Text_Temporary_Redirect :: "Temporary Redirect"
Status_Text_Permanent_Redirect :: "Permanent Redirect"

Status_Text_Bad_Request :: "Bad Request"
Status_Text_Unauthorized :: "Unauthorized"
Status_Text_Payment_Required :: "Payment Required"
Status_Text_Forbidden :: "Forbidden"
Status_Text_Not_Found :: "Not Found"
Status_Text_Method_Not_Allowed :: "Method Not Allowed"
Status_Text_Not_Acceptable :: "Not Acceptable"
Status_Text_Proxy_Auth_Required :: "Proxy Authentication Required"
Status_Text_Request_Timeout :: "Request Timeout"
Status_Text_Conflict :: "Conflict"
Status_Text_Gone :: "Gone"
Status_Text_Length_Required :: "Length Required"
Status_Text_Precondition_Failed :: "Precondition Failed"
Status_Text_Payload_Too_Large :: "Payload Too Large"
Status_Text_URI_Too_Long :: "URI Too Long"
Status_Text_Unsupported_Media_Type :: "Unsupported Media Type"
Status_Text_Range_Not_Satisfiable :: "Range Not Satisfiable"
Status_Text_Expectation_Failed :: "Expectation Failed"
Status_Text_Teapot :: "I'm a teapot"
Status_Text_Misdirected_Request :: "Misdirected Request"
Status_Text_Unprocessable_Entity :: "Unprocessable Entity"
Status_Text_Locked :: "Locked"
Status_Text_Failed_Dependency :: "Failed Dependency"
Status_Text_Too_Early :: "Too Early"
Status_Text_Upgrade_Required :: "Upgrade Required"
Status_Text_Precondition_Required :: "Precondition Required"
Status_Text_Too_Many_Requests :: "Too Many Requests"
Status_Text_Request_Header_Fields_Too_Large :: "Request Header Fields Too Large"
Status_Text_Unavailable_For_Legal_Reasons :: "Unavailable For Legal Reasons"

Status_Text_Internal_Server_Error :: "Internal Server Error"
Status_Text_Not_Implemented :: "Not Implemented"
Status_Text_Bad_Gateway :: "Bad Gateway"
Status_Text_Service_Unavailable :: "Service Unavailable"
Status_Text_Gateway_Timeout :: "Gateway Timeout"
Status_Text_HTTP_Version_Not_Supported :: "HTTP Version Not Supported"
Status_Text_Variant_Also_Negotiates :: "Variant Also Negotiates"
Status_Text_Insufficient_Storage :: "Insufficient Storage"
Status_Text_Loop_Detected :: "Loop Detected"
Status_Text_Not_Extended :: "Not Extended"
Status_Text_Network_Authentication_Required :: "Network Authentication Required"

status_phrase :: proc(code: int) -> string {
	switch code {
	case Status_Continue: return Status_Text_Continue
	case Status_Switching_Protocols: return Status_Text_Switching_Protocols
	case Status_Processing: return Status_Text_Processing
	case Status_Early_Hints: return Status_Text_Early_Hints
	case Status_OK: return Status_Text_OK
	case Status_Created: return Status_Text_Created
	case Status_Accepted: return Status_Text_Accepted
	case Status_Non_Authoritative_Information: return Status_Text_Non_Authoritative_Information
	case Status_No_Content: return Status_Text_No_Content
	case Status_Reset_Content: return Status_Text_Reset_Content
	case Status_Partial_Content: return Status_Text_Partial_Content
	case Status_Multi_Status: return Status_Text_Multi_Status
	case Status_Already_Reported: return Status_Text_Already_Reported
	case Status_IM_Used: return Status_Text_IM_Used
	case Status_Multiple_Choices: return Status_Text_Multiple_Choices
	case Status_Moved_Permanently: return Status_Text_Moved_Permanently
	case Status_Found: return Status_Text_Found
	case Status_See_Other: return Status_Text_See_Other
	case Status_Not_Modified: return Status_Text_Not_Modified
	case Status_Use_Proxy: return Status_Text_Use_Proxy
	case Status_Temporary_Redirect: return Status_Text_Temporary_Redirect
	case Status_Permanent_Redirect: return Status_Text_Permanent_Redirect
	case Status_Bad_Request: return Status_Text_Bad_Request
	case Status_Unauthorized: return Status_Text_Unauthorized
	case Status_Payment_Required: return Status_Text_Payment_Required
	case Status_Forbidden: return Status_Text_Forbidden
	case Status_Not_Found: return Status_Text_Not_Found
	case Status_Method_Not_Allowed: return Status_Text_Method_Not_Allowed
	case Status_Not_Acceptable: return Status_Text_Not_Acceptable
	case Status_Proxy_Auth_Required: return Status_Text_Proxy_Auth_Required
	case Status_Request_Timeout: return Status_Text_Request_Timeout
	case Status_Conflict: return Status_Text_Conflict
	case Status_Gone: return Status_Text_Gone
	case Status_Length_Required: return Status_Text_Length_Required
	case Status_Precondition_Failed: return Status_Text_Precondition_Failed
	case Status_Payload_Too_Large: return Status_Text_Payload_Too_Large
	case Status_URI_Too_Long: return Status_Text_URI_Too_Long
	case Status_Unsupported_Media_Type: return Status_Text_Unsupported_Media_Type
	case Status_Range_Not_Satisfiable: return Status_Text_Range_Not_Satisfiable
	case Status_Expectation_Failed: return Status_Text_Expectation_Failed
	case Status_Teapot: return Status_Text_Teapot
	case Status_Misdirected_Request: return Status_Text_Misdirected_Request
	case Status_Unprocessable_Entity: return Status_Text_Unprocessable_Entity
	case Status_Locked: return Status_Text_Locked
	case Status_Failed_Dependency: return Status_Text_Failed_Dependency
	case Status_Too_Early: return Status_Text_Too_Early
	case Status_Upgrade_Required: return Status_Text_Upgrade_Required
	case Status_Precondition_Required: return Status_Text_Precondition_Required
	case Status_Too_Many_Requests: return Status_Text_Too_Many_Requests
	case Status_Request_Header_Fields_Too_Large: return Status_Text_Request_Header_Fields_Too_Large
	case Status_Unavailable_For_Legal_Reasons: return Status_Text_Unavailable_For_Legal_Reasons
	case Status_Internal_Server_Error: return Status_Text_Internal_Server_Error
	case Status_Not_Implemented: return Status_Text_Not_Implemented
	case Status_Bad_Gateway: return Status_Text_Bad_Gateway
	case Status_Service_Unavailable: return Status_Text_Service_Unavailable
	case Status_Gateway_Timeout: return Status_Text_Gateway_Timeout
	case Status_HTTP_Version_Not_Supported: return Status_Text_HTTP_Version_Not_Supported
	case Status_Variant_Also_Negotiates: return Status_Text_Variant_Also_Negotiates
	case Status_Insufficient_Storage: return Status_Text_Insufficient_Storage
	case Status_Loop_Detected: return Status_Text_Loop_Detected
	case Status_Not_Extended: return Status_Text_Not_Extended
	case Status_Network_Authentication_Required: return Status_Text_Network_Authentication_Required
	case: return Status_Text_OK
	}
}
