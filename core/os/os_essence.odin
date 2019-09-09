package os;
EsData :: struct { _private : [4]rawptr, }
EsGeneric :: rawptr;
EsElement :: struct { _private : u8, };
EsObject :: rawptr;
EsLongDouble :: struct { value : [10]u8, };
EsNodeType :: u64;
EsError :: int;
EsHandle :: uint;
EsResponse :: i32;
EsFileOffset :: u64;
EsListViewIndex :: i32;
EsThreadEntryFunction :: distinct #type proc (EsGeneric);
EsComparisonCallbackFunction :: distinct #type proc (rawptr, rawptr, EsGeneric) -> i32;
EsSwapCallbackFunction :: distinct #type proc (rawptr, rawptr, EsGeneric);
EsCRTComparisonCallback :: distinct #type proc (rawptr, rawptr) -> i32;
EsMessageCallbackFunction :: distinct #type proc (EsObject, ^EsMessage, ^EsResponse);
EsUICallbackFunction :: distinct #type proc (^EsElement, ^EsMessage, ^EsResponse);
ES_SCANCODE_A ::  (0x1C);
ES_SCANCODE_B ::  (0x32);
ES_SCANCODE_C ::  (0x21);
ES_SCANCODE_D ::  (0x23);
ES_SCANCODE_E ::  (0x24);
ES_SCANCODE_F ::  (0x2B);
ES_SCANCODE_G ::  (0x34);
ES_SCANCODE_H ::  (0x33);
ES_SCANCODE_I ::  (0x43);
ES_SCANCODE_J ::  (0x3B);
ES_SCANCODE_K ::  (0x42);
ES_SCANCODE_L ::  (0x4B);
ES_SCANCODE_M ::  (0x3A);
ES_SCANCODE_N ::  (0x31);
ES_SCANCODE_O ::  (0x44);
ES_SCANCODE_P ::  (0x4D);
ES_SCANCODE_Q ::  (0x15);
ES_SCANCODE_R ::  (0x2D);
ES_SCANCODE_S ::  (0x1B);
ES_SCANCODE_T ::  (0x2C);
ES_SCANCODE_U ::  (0x3C);
ES_SCANCODE_V ::  (0x2A);
ES_SCANCODE_W ::  (0x1D);
ES_SCANCODE_X ::  (0x22);
ES_SCANCODE_Y ::  (0x35);
ES_SCANCODE_Z ::  (0x1A);
ES_SCANCODE_0 ::  (0x45);
ES_SCANCODE_1 ::  (0x16);
ES_SCANCODE_2 ::  (0x1E);
ES_SCANCODE_3 ::  (0x26);
ES_SCANCODE_4 ::  (0x25);
ES_SCANCODE_5 ::  (0x2E);
ES_SCANCODE_6 ::  (0x36);
ES_SCANCODE_7 ::  (0x3D);
ES_SCANCODE_8 ::  (0x3E);
ES_SCANCODE_9 ::  (0x46);
ES_SCANCODE_CAPS_LOCK :: 	(0x58);
ES_SCANCODE_SCROLL_LOCK :: 	(0x7E);
ES_SCANCODE_NUM_LOCK :: 	(0x77) ;
ES_SCANCODE_LEFT_SHIFT :: 	(0x12);
ES_SCANCODE_LEFT_CTRL :: 	(0x14);
ES_SCANCODE_LEFT_ALT :: 	(0x11);
ES_SCANCODE_LEFT_FLAG :: 	(0x11F);
ES_SCANCODE_RIGHT_SHIFT :: 	(0x59);
ES_SCANCODE_RIGHT_CTRL :: 	(0x114);
ES_SCANCODE_RIGHT_ALT :: 	(0x111);
ES_SCANCODE_PAUSE :: 	(0xE1);
ES_SCANCODE_CONTEXT_MENU ::  (0x127);
ES_SCANCODE_BACKSPACE :: 	(0x66);
ES_SCANCODE_ESCAPE :: 	(0x76);
ES_SCANCODE_INSERT :: 	(0x170);
ES_SCANCODE_HOME :: 	(0x16C);
ES_SCANCODE_PAGE_UP :: 	(0x17D);
ES_SCANCODE_DELETE :: 	(0x171);
ES_SCANCODE_END :: 		(0x169);
ES_SCANCODE_PAGE_DOWN :: 	(0x17A);
ES_SCANCODE_UP_ARROW :: 	(0x175);
ES_SCANCODE_LEFT_ARROW :: 	(0x16B);
ES_SCANCODE_DOWN_ARROW :: 	(0x172);
ES_SCANCODE_RIGHT_ARROW :: 	(0x174);
ES_SCANCODE_SPACE :: 	(0x29);
ES_SCANCODE_TAB :: 		(0x0D);
ES_SCANCODE_ENTER :: 	(0x5A);
ES_SCANCODE_SLASH :: 	(0x4A);
ES_SCANCODE_BACKSLASH :: 	(0x5D);
ES_SCANCODE_LEFT_BRACE :: 	(0x54);
ES_SCANCODE_RIGHT_BRACE :: 	(0x5B);
ES_SCANCODE_EQUALS :: 	(0x55);
ES_SCANCODE_BACKTICK :: 	(0x0E);
ES_SCANCODE_HYPHEN :: 	(0x4E);
ES_SCANCODE_SEMICOLON :: 	(0x4C);
ES_SCANCODE_QUOTE :: 	(0x52);
ES_SCANCODE_COMMA :: 	(0x41);
ES_SCANCODE_PERIOD :: 	(0x49);
ES_SCANCODE_NUM_DIVIDE ::  	 (0x14A);
ES_SCANCODE_NUM_MULTIPLY ::  (0x7C);
ES_SCANCODE_NUM_SUBTRACT ::  (0x7B);
ES_SCANCODE_NUM_ADD :: 	 (0x79);
ES_SCANCODE_NUM_ENTER :: 	 (0x15A);
ES_SCANCODE_NUM_POINT :: 	 (0x71);
ES_SCANCODE_NUM_0 :: 	 (0x70);
ES_SCANCODE_NUM_1 :: 	 (0x69);
ES_SCANCODE_NUM_2 :: 	 (0x72);
ES_SCANCODE_NUM_3 :: 	 (0x7A);
ES_SCANCODE_NUM_4 :: 	 (0x6B);
ES_SCANCODE_NUM_5 :: 	 (0x73);
ES_SCANCODE_NUM_6 :: 	 (0x74);
ES_SCANCODE_NUM_7 :: 	 (0x6C);
ES_SCANCODE_NUM_8 :: 	 (0x75);
ES_SCANCODE_NUM_9 :: 	 (0x7D);
ES_SCANCODE_PRINT_SCREEN_1 ::  (0x112) ;
ES_SCANCODE_PRINT_SCREEN_2 ::  (0x17C);
ES_SCANCODE_F1 ::   (0x05);
ES_SCANCODE_F2 ::   (0x06);
ES_SCANCODE_F3 ::   (0x04);
ES_SCANCODE_F4 ::   (0x0C);
ES_SCANCODE_F5 ::   (0x03);
ES_SCANCODE_F6 ::   (0x0B);
ES_SCANCODE_F7 ::   (0x83);
ES_SCANCODE_F8 ::   (0x0A);
ES_SCANCODE_F9 ::   (0x01);
ES_SCANCODE_F10 ::  (0x09);
ES_SCANCODE_F11 ::  (0x78);
ES_SCANCODE_F12 ::  (0x07);
ES_SCANCODE_ACPI_POWER ::  	(0x137);
ES_SCANCODE_ACPI_SLEEP ::  	(0x13F);
ES_SCANCODE_ACPI_WAKE ::   	(0x15E);
ES_SCANCODE_MM_NEXT :: 	(0x14D);
ES_SCANCODE_MM_PREVIOUS :: 	(0x115);
ES_SCANCODE_MM_STOP :: 	(0x13B);
ES_SCANCODE_MM_PAUSE :: 	(0x134);
ES_SCANCODE_MM_MUTE :: 	(0x123);
ES_SCANCODE_MM_QUIETER :: 	(0x121);
ES_SCANCODE_MM_LOUDER :: 	(0x132);
ES_SCANCODE_MM_SELECT :: 	(0x150);
ES_SCANCODE_MM_EMAIL :: 	(0x148);
ES_SCANCODE_MM_CALC :: 	(0x12B);
ES_SCANCODE_MM_FILES :: 	(0x140);
ES_SCANCODE_WWW_SEARCH :: 	(0x110);
ES_SCANCODE_WWW_HOME :: 	(0x13A);
ES_SCANCODE_WWW_BACK :: 	(0x138);
ES_SCANCODE_WWW_FORWARD :: 	(0x130);
ES_SCANCODE_WWW_STOP :: 	(0x128);
ES_SCANCODE_WWW_REFRESH :: 	(0x120);
ES_SCANCODE_WWW_STARRED :: 	(0x118);
ES_PROCESS_STATE_ALL_THREADS_TERMINATED :: 	(1);
ES_PROCESS_STATE_TERMINATING :: 		(2);
ES_PROCESS_STATE_CRASHED :: 		(4);
ES_FLAGS_DEFAULT ::  (0);
ES_SUCCESS ::  	 (-1);
ES_ERROR_BUFFER_TOO_SMALL :: 		(-2);
ES_ERROR_UNKNOWN_OPERATION_FAILURE ::  	(-7);
ES_ERROR_NO_MESSAGES_AVAILABLE :: 		(-9);
ES_ERROR_MESSAGE_QUEUE_FULL :: 		(-10);
ES_ERROR_MESSAGE_NOT_HANDLED_BY_GUI :: 	(-13);
ES_ERROR_PATH_NOT_WITHIN_MOUNTED_VOLUME :: 	(-14);
ES_ERROR_PATH_NOT_TRAVERSABLE :: 		(-15);
ES_ERROR_FILE_ALREADY_EXISTS :: 		(-19);
ES_ERROR_FILE_DOES_NOT_EXIST :: 		(-20);
ES_ERROR_DRIVE_ERROR_FILE_DAMAGED :: 	(-21) ;
ES_ERROR_ACCESS_NOT_WITHIN_FILE_BOUNDS :: 	(-22) ;
ES_ERROR_FILE_PERMISSION_NOT_GRANTED :: 	(-23);
ES_ERROR_FILE_IN_EXCLUSIVE_USE :: 		(-24);
ES_ERROR_FILE_CANNOT_GET_EXCLUSIVE_USE :: 	(-25);
ES_ERROR_INCORRECT_NODE_TYPE :: 		(-26);
ES_ERROR_EVENT_NOT_SET :: 			(-27);
ES_ERROR_TIMEOUT_REACHED :: 		(-29);
ES_ERROR_REQUEST_CLOSED_BEFORE_COMPLETE ::  (-30);
ES_ERROR_NO_CHARACTER_AT_COORDINATE :: 	(-31);
ES_ERROR_FILE_ON_READ_ONLY_VOLUME :: 	(-32);
ES_ERROR_USER_CANCELED_IO :: 		(-33);
ES_ERROR_INVALID_DIMENSIONS :: 		(-34);
ES_ERROR_DRIVE_CONTROLLER_REPORTED :: 	(-35);
ES_ERROR_COULD_NOT_ISSUE_PACKET :: 		(-36);
ES_ERROR_HANDLE_TABLE_FULL :: 		(-37);
ES_ERROR_COULD_NOT_RESIZE_FILE :: 		(-38);
ES_ERROR_DIRECTORY_NOT_EMPTY :: 		(-39);
ES_ERROR_UNSUPPORTED_FILESYSTEM :: 		(-40);
ES_ERROR_NODE_ALREADY_DELETED :: 		(-41);
ES_ERROR_NODE_IS_ROOT :: 			(-42);
ES_ERROR_VOLUME_MISMATCH :: 		(-43);
ES_ERROR_TARGET_WITHIN_SOURCE :: 		(-44);
ES_ERROR_TARGET_INVALID_TYPE :: 		(-45);
ES_ERROR_NOTHING_TO_DRAW :: 		(-46);
ES_ERROR_MALFORMED_NODE_PATH :: 		(-47);
ES_ERROR_OUT_OF_CACHE_RESOURCES :: 		(-48);
ES_ERROR_TARGET_IS_SOURCE :: 		(-49);
ES_ERROR_INVALID_NAME :: 			(-50);
ES_ERROR_CORRUPT_DATA :: 			(-51);
ES_ERROR_INSUFFICIENT_RESOURCES :: 		(-52);
ES_ERROR_UNSUPPORTED_FEATURE :: 		(-53);
ES_ERROR_FILE_TOO_FRAGMENTED :: 		(-54);
ES_ERROR_DRIVE_FULL :: 			(-55);
ES_ERROR_COULD_NOT_RESOLVE_SYMBOL :: 	(-56);
ES_ERROR_ALREADY_EMBEDDED :: 		(-57);
ES_SYSTEM_CONSTANT_TIME_STAMP_UNITS_PER_MICROSECOND ::  (0);
ES_SYSTEM_CONSTANT_NO_FANCY_GRAPHICS :: 		    (2);
ES_SYSTEM_CONSTANT_REPORTED_PROBLEMS :: 		    (3);
ES_INVALID_HANDLE ::  		((EsHandle) (0));
ES_CURRENT_THREAD :: 	 	((EsHandle) (0x10));
ES_CURRENT_PROCESS :: 	 	((EsHandle) (0x11));
ES_SURFACE_UI_SHEET :: 		((EsHandle) (0x20));
ES_SURFACE_WALLPAPER :: 		((EsHandle) (0x21));
ES_DRAW_ALPHA_OVERWRITE :: 		(0x100);
ES_DRAW_ALPHA_FULL :: 		(0x200) ;
ES_WAIT_NO_TIMEOUT ::  (-1);
ES_MAX_WAIT_COUNT ::  		(16);
ES_MAX_DIRECTORY_CHILD_NAME_LENGTH ::  (256);
ES_PROCESS_EXECUTABLE_NOT_LOADED ::  0;
ES_PROCESS_EXECUTABLE_FAILED_TO_LOAD ::  1;
ES_PROCESS_EXECUTABLE_LOADED ::  2;
ES_SNAPSHOT_MAX_PROCESS_NAME_LENGTH ::  (80);
ES_SYSTEM_SNAPSHOT_PROCESSES ::  		(1);
ES_SYSTEM_SNAPSHOT_DRIVES ::  		(2);
ES_NOT_HANDLED ::  (-1);
ES_HANDLED ::  (0);
ES_REJECTED ::  (-2);
ES_SHARED_MEMORY_MAXIMUM_SIZE ::  (                  (1024) * 1024 * 1024 * 1024);
ES_SHARED_MEMORY_NAME_MAX_LENGTH ::  (32);
ES_MAP_OBJECT_ALL ::  (0);
ES_DRAW_STRING_HALIGN_LEFT ::  	(1);
ES_DRAW_STRING_HALIGN_RIGHT ::  	(2);
ES_DRAW_STRING_HALIGN_CENTER ::  	(3);
ES_DRAW_STRING_VALIGN_TOP ::  	(4);
ES_DRAW_STRING_VALIGN_BOTTOM ::  	(8);
ES_DRAW_STRING_VALIGN_CENTER ::  	(12);
ES_DRAW_STRING_CLIP :: 		(0);
ES_DRAW_STRING_WORD_WRAP ::  	(16);
ES_DRAW_STRING_ELLIPSIS :: 		(32);
ES_NODE_READ_NONE :: 		(0x0);
ES_NODE_READ_BLOCK :: 		(0x1);
ES_NODE_READ_ACCESS :: 		(0x2);
ES_NODE_READ_EXCLUSIVE :: 		(0x3);
ES_NODE_WRITE_NONE :: 		(0x00);
ES_NODE_WRITE_BLOCK :: 		(0x10);
ES_NODE_WRITE_ACCESS :: 		(0x20);
ES_NODE_WRITE_EXCLUSIVE :: 		(0x30);
ES_NODE_RESIZE_NONE :: 		(0x000);
ES_NODE_RESIZE_BLOCK :: 		(0x100);
ES_NODE_RESIZE_ACCESS :: 		(0x200);
ES_NODE_RESIZE_EXCLUSIVE :: 	(0x300);
ES_NODE_FAIL_IF_FOUND :: 		(0x1000);
ES_NODE_FAIL_IF_NOT_FOUND :: 	(0x2000);
ES_NODE_CREATE_DIRECTORIES :: 	(0x8000)  ;
ES_NODE_POSIX_NAMESPACE :: 		(0x10000) ;
ES_DIRECTORY_CHILDREN_UNKNOWN :: 	(               (-1));
ES_MEMORY_OPEN_FAIL_IF_FOUND ::      (0x1000);
ES_MEMORY_OPEN_FAIL_IF_NOT_FOUND ::  (0x2000);
ES_MAP_OBJECT_READ_WRITE ::         (0);
ES_MAP_OBJECT_READ_ONLY ::          (1);
ES_MAP_OBJECT_COPY_ON_WRITE ::      (2);
ES_BOX_STYLE_OUTWARDS ::     (0x01) ;
ES_BOX_STYLE_INWARDS ::      (0x02) ;
ES_BOX_STYLE_NEUTRAL ::      (0x03) ;
ES_BOX_STYLE_FLAT ::         (0x04) ;
ES_BOX_STYLE_NONE ::         (0x05) ;
ES_BOX_STYLE_SELECTED ::     (0x06) ;
ES_BOX_STYLE_PUSHED ::       (0x07) ;
ES_BOX_STYLE_DOTTED ::       (0x80);
ES_BOX_COLOR_GRAY ::         (0xC0C0C0);
ES_BOX_COLOR_DARK_GRAY ::    (0x808080);
ES_BOX_COLOR_WHITE ::        (0xFFFFFF);
ES_BOX_COLOR_BLUE ::         (0x000080);
ES_BOX_COLOR_TRANSPARENT ::  (0xFF00FF);
ES_BOX_COLOR_BLACK :: 	 (0x000000);
ES_STRING_FORMAT_ENOUGH_SPACE :: 	(                  (-1));
ES_POSIX_SYSCALL_GET_POSIX_FD_PATH ::  			(0x10000);
ES_SURFACE_FULL_ALPHA :: 	(1);
ES_PERMISSION_ACCESS_SYSTEM_FILES ::   	(1 << 0);
ES_PERMISSION_ACCESS_USER_FILES ::   	(1 << 1);
ES_PERMISSION_PROCESS_CREATE :: 		(1 << 2);
ES_PERMISSION_PROCESS_OPEN :: 		(1 << 3);
ES_PERMISSION_SCREEN_MODIFY :: 		(1 << 4)	;
ES_PERMISSION_SHUTDOWN :: 			(1 << 5);
ES_PERMISSION_TAKE_SYSTEM_SNAPSHOT :: 	(1 << 6);
ES_PERMISSION_WINDOW_OPEN :: 		(1 << 7);
ES_PERMISSION_ALL :: 			(                  (-1));
ES_PERMISSION_INHERIT :: 			(                  (1 << 63));
ES_PANEL_WRAP :: 		(                  (0x0001) << 32);
ES_PANEL_H_LEFT :: 		(                  (0x0010) << 32);
ES_PANEL_H_RIGHT :: 	(                  (0x0020) << 32);
ES_PANEL_H_CENTER :: 	(                  (0x0040) << 32);
ES_PANEL_H_JUSTIFY :: 	(                  (0x0080) << 32);
ES_PANEL_V_TOP :: 		(                  (0x0100) << 32);
ES_PANEL_V_BOTTOM :: 	(                  (0x0200) << 32);
ES_PANEL_V_CENTER :: 	(                  (0x0400) << 32);
ES_PANEL_V_JUSTIFY :: 	(                  (0x0800) << 32);
ES_PANEL_H_SCROLL :: 	(                  (0x1000) << 32);
ES_PANEL_V_SCROLL :: 	(                  (0x2000) << 32);
ES_CELL_H_PUSH ::           (                  (0x0001) << 16);
ES_CELL_H_EXPAND ::         (                  (0x0002) << 16);
ES_CELL_H_LEFT ::           (                  (0x0004) << 16);
ES_CELL_H_RIGHT ::          (                  (0x0008) << 16);
ES_CELL_H_SHRINK :: 	(                  (0x0010) << 16);
ES_CELL_V_PUSH ::           (                  (0x0100) << 16);
ES_CELL_V_EXPAND ::         (                  (0x0200) << 16);
ES_CELL_V_TOP ::            (                  (0x0400) << 16);
ES_CELL_V_BOTTOM ::         (                  (0x0800) << 16);
ES_CELL_V_SHRINK :: 	(                  (0x1000) << 16);
ES_CELL_NEW_BAND :: 	(                  (0x8000) << 16);
ES_CELL_HIDDEN :: 		(                  (0xFFFF) << 16);
ES_ELEMENT_DO_NOT_FREE_STYLE_OVERRIDE ::  	(1 << 0);
ES_ELEMENT_RICH_TEXT :: 			(1 << 1);
ES_ELEMENT_FOCUSABLE :: 			(1 << 2);
ES_ELEMENT_Z_STACK :: 			(1 << 3) ;
ES_ELEMENT_HIDDEN :: 			(1 << 4);
ES_ELEMENT_USE_CHILD_AS_PARENT :: 		(1 << 5) ;
ES_TEXTBOX_MULTILINE :: 			(1 << 0);
ES_TEXTBOX_BORDERED :: 			(1 << 1);
ES_BUTTON_DEFAULT :: 			(                  (1) << 32);
ES_BUTTON_DANGEROUS :: 			(                  (1) << 33);
ES_SCROLLBAR_VERTICAL :: 			(                  (0) << 32);
ES_SCROLLBAR_HORIZONTAL :: 			(                  (1) << 32);
ES_LIST_VIEW_INDEX_GROUP_HEADER ::  (-1);
ES_LIST_VIEW_ITEM_CONTENT_TEXT :: 		(1 << 0);
ES_LIST_VIEW_ITEM_CONTENT_ICON :: 		(1 << 1);
ES_LIST_VIEW_ITEM_CONTENT_INDENTATION :: 	(1 << 2);
ES_LIST_VIEW_ITEM_STATE_SELECTED :: 	(1 << 0);
ES_LIST_VIEW_ITEM_STATE_CHECKED :: 		(1 << 1);
ES_LIST_VIEW_ITEM_STATE_HIDDEN :: 		(1 << 2);
ES_LIST_VIEW_ITEM_STATE_EXPANDABLE :: 	(1 << 3);
ES_LIST_VIEW_ITEM_STATE_CHECKABLE :: 	(1 << 4);
ES_LIST_VIEW_ITEM_STATE_DROP_TARGET :: 	(1 << 5);
ES_LIST_VIEW_ITEM_STATE_COLLAPSABLE :: 	(1 << 6);
ES_LIST_VIEW_ITEM_STATE_PARTIAL_CHECK :: 	(1 << 7);
ES_LIST_VIEW_ITEM_STATE_DRAG_SOURCE :: 	(1 << 8);
ES_LIST_VIEW_ITEM_STATE_CUT :: 		(1 << 9);
ES_LIST_VIEW_FIND_ITEM_FROM_Y_POSITION ::  		(0);
ES_LIST_VIEW_FIND_ITEM_FROM_TEXT_PREFIX ::  	(1);
ES_LIST_VIEW_FIND_ITEM_NON_HIDDEN ::  		(2);
ES_LIST_VIEW_FIND_ITEM_PARENT :: 			(3);
ES_LIST_VIEW_COLUMN_DEFAULT_WIDTH_PRIMARY ::  (300);
ES_LIST_VIEW_COLUMN_DEFAULT_WIDTH_SECONDARY ::  (150);
ES_LIST_VIEW_COLUMN_PRIMARY ::  (1);
ES_LIST_VIEW_COLUMN_RIGHT_ALIGNED ::  (2);
ES_LIST_VIEW_COLUMN_SORT_ASCENDING ::  (8);
ES_LIST_VIEW_COLUMN_SORT_DESCENDING ::  (16);
ES_LIST_VIEW_COLUMN_SORTABLE ::  (32);
ES_LIST_VIEW_SINGLE_SELECT :: 		(1 <<  0) ;
ES_LIST_VIEW_MULTI_SELECT :: 		(1 <<  1) ;
ES_LIST_VIEW_HAS_COLUMNS :: 		(1 <<  2) ;
ES_LIST_VIEW_HAS_GROUPS :: 			(1 <<  3) ;
ES_LIST_VIEW_FIXED_HEIGHT :: 		(1 <<  4) ;
ES_LIST_VIEW_VARIABLE_HEIGHT :: 		(1 <<  5) ;
ES_LIST_VIEW_TREE :: 			(1 <<  6) ;
ES_LIST_VIEW_TILED :: 			(1 <<  7) ;
ES_LIST_VIEW_ALT_BACKGROUND :: 		(1 <<  8) ;
ES_LIST_VIEW_BORDERED :: 			(1 <<  9) ;
ES_LIST_VIEW_NO_BACKGROUND :: 		(1 << 10) ;
ES_LIST_VIEW_DROP_TARGET_ORDERED :: 	(1 << 11) ;
ES_LIST_VIEW_DROP_TARGET_UNORDERED :: 	(1 << 12) ;
ES_LIST_VIEW_ROW_DIVIDERS :: 		(1 << 13) ;
ES_LIST_VIEW_STATIC_GROUP_HEADERS :: 	(1 << 14) ;
ES_LIST_VIEW_COLLAPSABLE_GROUPS :: 		(1 << 15) ;
ES_LIST_VIEW_INTERNAL_SELECTION_STORAGE ::  (1 << 16) ;
ES_LIST_VIEW_HAND_CURSOR :: 		(1 << 17) ;
ES_LIST_VIEW_NO_ITEM_BACKGROUNDS :: 	(1 << 18) ;
ES_LIST_VIEW_RICH_TEXT :: 			(1 << 20) ;
ES_LIST_VIEW_LABELS_BELOW :: 		(1 << 21) ;
ES_LIST_VIEW_MAXIMUM_ITEMS ::  (10 * 1000 * 1000);
ES_LIST_VIEW_MAXIMUM_GROUPS ::  (10 * 1000);
ES_LIST_VIEW_TRANSITION_BACKWARDS ::  		(1);
ES_LIST_VIEW_TRANSITION_DRAW_NEW_CONTENTS_ONCE ::  	(2) ;
EsFatalError :: enum {
	ES_FATAL_ERROR_INVALID_BUFFER,
	ES_FATAL_ERROR_UNKNOWN_SYSCALL,
	ES_FATAL_ERROR_INVALID_MEMORY_REGION,
	ES_FATAL_ERROR_MEMORY_REGION_LOCKED_BY_KERNEL,
	ES_FATAL_ERROR_PATH_LENGTH_EXCEEDS_LIMIT,
	ES_FATAL_ERROR_INVALID_HANDLE,
	ES_FATAL_ERROR_MUTEX_NOT_ACQUIRED_BY_THREAD,
	ES_FATAL_ERROR_MUTEX_ALREADY_ACQUIRED,
	ES_FATAL_ERROR_BUFFER_NOT_ACCESSIBLE,
	ES_FATAL_ERROR_SHARED_MEMORY_REGION_TOO_LARGE,
	ES_FATAL_ERROR_SHARED_MEMORY_STILL_MAPPED,
	ES_FATAL_ERROR_COULD_NOT_LOAD_FONT,
	ES_FATAL_ERROR_COULD_NOT_DRAW_FONT,
	ES_FATAL_ERROR_COULD_NOT_ALLOCATE_MEMORY,
	ES_FATAL_ERROR_INCORRECT_FILE_ACCESS,
	ES_FATAL_ERROR_TOO_MANY_WAIT_OBJECTS,
	ES_FATAL_ERROR_INCORRECT_NODE_TYPE,
	ES_FATAL_ERROR_PROCESSOR_EXCEPTION,
	ES_FATAL_ERROR_UNKNOWN,
	ES_FATAL_ERROR_RECURSIVE_BATCH,
	ES_FATAL_ERROR_CORRUPT_HEAP,
	ES_FATAL_ERROR_CORRUPT_LINKED_LIST,
	ES_FATAL_ERROR_INDEX_OUT_OF_BOUNDS,
	ES_FATAL_ERROR_INVALID_STRING_LENGTH,
	ES_FATAL_ERROR_SPINLOCK_NOT_ACQUIRED,
	ES_FATAL_ERROR_UNKNOWN_SNAPSHOT_TYPE,
	ES_FATAL_ERROR_PROCESS_ALREADY_ATTACHED,
	ES_FATAL_ERROR_INTERNAL,
	ES_FATAL_ERROR_INSUFFICIENT_PERMISSIONS,
	ES_FATAL_ERROR_ABORT,
	ES_FATAL_ERROR_COUNT,
}

EsSyscallType :: enum {
	ES_SYSCALL_ALLOCATE,
	ES_SYSCALL_FREE,
	ES_SYSCALL_SHARE_MEMORY,
	ES_SYSCALL_MAP_OBJECT,
	ES_SYSCALL_OPEN_SHARED_MEMORY,
	ES_SYSCALL_CREATE_PROCESS,
	ES_SYSCALL_GET_CREATION_ARGUMENT,
	ES_SYSCALL_TERMINATE_THREAD,
	ES_SYSCALL_CREATE_THREAD,
	ES_SYSCALL_WAIT,
	ES_SYSCALL_TERMINATE_PROCESS,
	ES_SYSCALL_CREATE_EVENT,
	ES_SYSCALL_SET_EVENT,
	ES_SYSCALL_RESET_EVENT,
	ES_SYSCALL_POLL_EVENT,
	ES_SYSCALL_PAUSE_PROCESS,
	ES_SYSCALL_CRASH_PROCESS,
	ES_SYSCALL_GET_THREAD_ID,
	ES_SYSCALL_GET_PROCESS_STATE,
	ES_SYSCALL_YIELD_SCHEDULER,
	ES_SYSCALL_SLEEP,
	ES_SYSCALL_OPEN_PROCESS,
	ES_SYSCALL_SET_TLS,
	ES_SYSCALL_TIMER_SET,
	ES_SYSCALL_TIMER_CREATE,
	ES_SYSCALL_GET_PROCESS_STATUS,
	ES_SYSCALL_CREATE_SURFACE,
	ES_SYSCALL_GET_LINEAR_BUFFER,
	ES_SYSCALL_INVALIDATE_RECTANGLE,
	ES_SYSCALL_COPY_TO_SCREEN,
	ES_SYSCALL_FORCE_SCREEN_UPDATE,
	ES_SYSCALL_FILL_RECTANGLE,
	ES_SYSCALL_COPY_SURFACE,
	ES_SYSCALL_CLEAR_MODIFIED_REGION,
	ES_SYSCALL_DRAW_SURFACE,
	ES_SYSCALL_REDRAW_ALL,
	ES_SYSCALL_DRAW_BOX,
	ES_SYSCALL_DRAW_BITMAP,
	ES_SYSCALL_SURFACE_RESET,
	ES_SYSCALL_SURFACE_SHARE,
	ES_SYSCALL_DRAW_STYLED_BOX,
	ES_SYSCALL_SURFACE_SCROLL,
	ES_SYSCALL_RESIZE_SURFACE,
	ES_SYSCALL_GET_MESSAGE,
	ES_SYSCALL_POST_MESSAGE,
	ES_SYSCALL_POST_MESSAGE_REMOTE,
	ES_SYSCALL_WAIT_MESSAGE,
	ES_SYSCALL_CREATE_WINDOW,
	ES_SYSCALL_UPDATE_WINDOW,
	ES_SYSCALL_SET_CURSOR_STYLE,
	ES_SYSCALL_MOVE_WINDOW,
	ES_SYSCALL_GET_WINDOW_BOUNDS,
	ES_SYSCALL_RESET_CLICK_CHAIN,
	ES_SYSCALL_GET_CURSOR_POSITION,
	ES_SYSCALL_SET_CURSOR_POSITION,
	ES_SYSCALL_COPY,
	ES_SYSCALL_GET_CLIPBOARD_HEADER,
	ES_SYSCALL_PASTE_TEXT,
	ES_SYSCALL_SET_FOCUSED_WINDOW,
	ES_SYSCALL_SET_WINDOW_TITLE,
	ES_SYSCALL_GET_SCREEN_BOUNDS,
	ES_SYSCALL_WINDOW_OPEN,
	ES_SYSCALL_WINDOW_SET_BLEND_BOUNDS,
	ES_SYSCALL_WINDOW_GET_BLEND_BOUNDS,
	ES_SYSCALL_WINDOW_GET_ID,
	ES_SYSCALL_SET_WINDOW_ALPHA,
	ES_SYSCALL_DOCKED_WINDOW_CREATE,
	ES_SYSCALL_WINDOW_SHARE,
	ES_SYSCALL_SET_EMBED_WINDOW,
	ES_SYSCALL_OPEN_NODE,
	ES_SYSCALL_READ_FILE_SYNC,
	ES_SYSCALL_WRITE_FILE_SYNC,
	ES_SYSCALL_RESIZE_FILE,
	ES_SYSCALL_REFRESH_NODE_INFORMATION,
	ES_SYSCALL_ENUMERATE_DIRECTORY_CHILDREN,
	ES_SYSCALL_DELETE_NODE,
	ES_SYSCALL_MOVE_NODE,
	ES_SYSCALL_READ_CONSTANT_BUFFER,
	ES_SYSCALL_SHARE_CONSTANT_BUFFER,
	ES_SYSCALL_CREATE_CONSTANT_BUFFER,
	ES_SYSCALL_EXECUTE,
	ES_SYSCALL_INSTANCE_CREATE_REMOTE,
	ES_SYSCALL_MAILSLOT_SEND_DATA,
	ES_SYSCALL_MAILSLOT_SEND_MESSAGE,
	ES_SYSCALL_MAILSLOT_SHARE,
	ES_SYSCALL_PIPE_CREATE,
	ES_SYSCALL_PIPE_WRITE,
	ES_SYSCALL_PIPE_READ,
	ES_SYSCALL_USER_GET_HOME_FOLDER,
	ES_SYSCALL_USER_LOGIN,
	ES_SYSCALL_GET_SYSTEM_CONSTANTS,
	ES_SYSCALL_TAKE_SYSTEM_SNAPSHOT,
	ES_SYSCALL_SET_SYSTEM_CONSTANT,
	ES_SYSCALL_GET_SYSTEM_INFORMATION,
	ES_SYSCALL_PRINT,
	ES_SYSCALL_CLOSE_HANDLE,
	ES_SYSCALL_BATCH,
	ES_SYSCALL_SHUTDOWN,
	ES_SYSCALL_POSIX,
	ES_SYSCALL_COUNT,
}

EsStandardFont :: enum {
	ES_STANDARD_FONT_REGULAR,
	ES_STANDARD_FONT_BOLD,
	ES_STANDARD_FONT_MONOSPACED,
}

EsMessageType :: enum {
	ES_MESSAGE_WM_START =  0x1000,
	ES_MESSAGE_MOUSE_MOVED =  0x1001,
	ES_MESSAGE_WINDOW_ACTIVATED =  0x1003,
	ES_MESSAGE_WINDOW_DEACTIVATED =  0x1004,
	ES_MESSAGE_WINDOW_DESTROYED =  0x1005,
	ES_MESSAGE_MOUSE_EXIT =  0x1006 ,
	ES_MESSAGE_CLICK_REPEAT =  0x1009,
	ES_MESSAGE_WINDOW_RESIZED =  0x100B,
	ES_MESSAGE_MOUSE_LEFT_PRESSED =  0x100C ,
	ES_MESSAGE_MOUSE_LEFT_RELEASED =  0x100D,
	ES_MESSAGE_MOUSE_RIGHT_PRESSED =  0x100E,
	ES_MESSAGE_MOUSE_RIGHT_RELEASED =  0x100F,
	ES_MESSAGE_MOUSE_MIDDLE_PRESSED =  0x1010,
	ES_MESSAGE_MOUSE_MIDDLE_RELEASED =  0x1011 ,
	ES_MESSAGE_KEY_PRESSED =  0x1012,
	ES_MESSAGE_KEY_RELEASED =  0x1013,
	ES_MESSAGE_UPDATE_WINDOW =  0x1014,
	ES_MESSAGE_WM_END =  0x13FF,
	ES_MESSAGE_PAINT =  0x2000	,
	ES_MESSAGE_DESTROY =  0x2001	,
	ES_MESSAGE_MEASURE =  0x2002	,
	ES_MESSAGE_SIZE =  0x2003	,
	ES_MESSAGE_ADD_CHILD =  0x2004	,
	ES_MESSAGE_REMOVE_CHILD =  0x2005	,
	ES_MESSAGE_HIT_TEST =  0x2006	,
	ES_MESSAGE_HOVERED_START =  0x2007	,
	ES_MESSAGE_HOVERED_END =  0x2008	,
	ES_MESSAGE_PRESSED_START =  0x2009	,
	ES_MESSAGE_PRESSED_END =  0x200A	,
	ES_MESSAGE_FOCUSED_START =  0x200B	,
	ES_MESSAGE_FOCUSED_END =  0x200C	,
	ES_MESSAGE_FOCUS_WITHIN_START =  0x200D	,
	ES_MESSAGE_FOCUS_WITHIN_END =  0x200E	,
	ES_MESSAGE_Z_ORDER =  0x2010	,
	ES_MESSAGE_ANIMATE =  0x2011	,
	ES_MESSAGE_MOUSE_DRAGGED =  0x2012	,
	ES_MESSAGE_KEY_TYPED =  0x2013	,
	ES_MESSAGE_PAINT_BACKGROUND =  0x2014	,
	ES_MESSAGE_PAINT_FOREGROUND =  0x2015	,
	ES_MESSAGE_ENSURE_VISIBLE =  0x2016	,
	ES_MESSAGE_GET_CURSOR =  0x2017	,
	ES_MESSAGE_WINDOW_CREATED =  0x2018	,
	ES_MESSAGE_CLICKED =  0x3000	,
	ES_MESSAGE_SCROLLBAR_MOVED =  0x3001	,
	ES_MESSAGE_RECALCULATE_CONTENT_SIZE =  0x3002	,
	ES_MESSAGE_DESKTOP_EXECUTE =  0x4800,
	ES_MESSAGE_POWER_BUTTON_PRESSED =  0x4801,
	ES_MESSAGE_TASKBAR_WINDOW_ADD =  0x4804,
	ES_MESSAGE_TASKBAR_WINDOW_REMOVE =  0x4805,
	ES_MESSAGE_TASKBAR_WINDOW_ACTIVATE =  0x4806,
	ES_MESSAGE_TASKBAR_WINDOW_SET_TITLE =  0x4807,
	ES_MESSAGE_DOCKED_WINDOW_CREATE =  0x4808,
	ES_MESSAGE_PROGRAM_CRASH =  0x4C00,
	ES_MESSAGE_PROGRAM_FAILED_TO_START =  0x4C01,
	ES_MESSAGE_RECEIVE_DATA =  0x5100,
	ES_MESSAGE_MAILSLOT_CLOSED =  0x5101,
	ES_MESSAGE_CLIPBOARD_UPDATED =  0x5001,
	ES_MESSAGE_SYSTEM_CONSTANT_UPDATED =  0x5004,
	ES_MESSAGE_TIMER =  0x5006,
	ES_MESSAGE_OBJECT_DESTROY =  0x5007,
	ES_MESSAGE_LIST_VIEW_GET_ITEM_CONTENT =  0x6000,
	ES_MESSAGE_LIST_VIEW_SET_ITEM_STATE =  0x6001,
	ES_MESSAGE_LIST_VIEW_GET_ITEM_STATE =  0x6002,
	ES_MESSAGE_LIST_VIEW_PAINT_ITEM =  0x6003 ,
	ES_MESSAGE_LIST_VIEW_PAINT_CELL =  0x6004 ,
	ES_MESSAGE_LIST_VIEW_SORT_COLUMN =  0x6005,
	ES_MESSAGE_LIST_VIEW_CHOOSE_ITEM =  0x6006,
	ES_MESSAGE_LIST_VIEW_FIND_ITEM =  0x6007,
	ES_MESSAGE_LIST_VIEW_TOGGLE_DISCLOSURE =  0x6008,
	ES_MESSAGE_LIST_VIEW_MEASURE_ITEM_HEIGHT =  0x6009,
	ES_MESSAGE_LIST_VIEW_LAYOUT_ITEM =  0x600A,
	ES_MESSAGE_LIST_VIEW_SET_ITEM_VISIBILITY =  0x600B,
	ES_MESSAGE_LIST_VIEW_RELAY_MESSAGE =  0x600C,
	ES_MESSAGE_LIST_VIEW_SET_ITEM_POSITION =  0x600D,
	ES_MESSAGE_USER_START =  0x8000,
	ES_MESSAGE_USER_END =  0xBFFF,
}

EsDrawMode :: enum {
	ES_DRAW_MODE_REPEAT_FIRST =  1 ,
	ES_DRAW_MODE_STRECH,
	ES_DRAW_MODE_REPEAT,
	ES_DRAW_MODE_NONE,
}

EsClipboardFormat :: enum {
	ES_CLIPBOARD_FORMAT_EMPTY,
	ES_CLIPBOARD_FORMAT_TEXT,
	ES_CLIPBOARD_FORMAT_FILE_LIST,
}

EsColorFormat :: enum {
	ES_COLOR_FORMAT_32_XRGB,
}

EsCursorStyle :: enum {
	ES_CURSOR_NORMAL,
	ES_CURSOR_TEXT,
	ES_CURSOR_RESIZE_VERTICAL,
	ES_CURSOR_RESIZE_HORIZONTAL,
	ES_CURSOR_RESIZE_DIAGONAL_1,
	ES_CURSOR_RESIZE_DIAGONAL_2,
	ES_CURSOR_SPLIT_VERTICAL,
	ES_CURSOR_SPLIT_HORIZONTAL,
	ES_CURSOR_HAND_HOVER,
	ES_CURSOR_HAND_DRAG,
	ES_CURSOR_HAND_POINT,
	ES_CURSOR_SCROLL_UP_LEFT,
	ES_CURSOR_SCROLL_UP,
	ES_CURSOR_SCROLL_UP_RIGHT,
	ES_CURSOR_SCROLL_LEFT,
	ES_CURSOR_SCROLL_CENTER,
	ES_CURSOR_SCROLL_RIGHT,
	ES_CURSOR_SCROLL_DOWN_LEFT,
	ES_CURSOR_SCROLL_DOWN,
	ES_CURSOR_SCROLL_DOWN_RIGHT,
	ES_CURSOR_SELECT_LINES,
	ES_CURSOR_DROP_TEXT,
	ES_CURSOR_CROSS_HAIR_PICK,
	ES_CURSOR_CROSS_HAIR_RESIZE,
	ES_CURSOR_MOVE_HOVER,
	ES_CURSOR_MOVE_DRAG,
	ES_CURSOR_ROTATE_HOVER,
	ES_CURSOR_ROTATE_DRAG,
	ES_CURSOR_BLANK,
}

EsWindowStyle :: enum {
	ES_WINDOW_NORMAL,
	ES_WINDOW_CONTAINER,
	ES_WINDOW_MENU,
}

ES_NODE_FILE :: 		(0);
ES_NODE_DIRECTORY :: 	(0x4000);
ES_NODE_INVALID :: 		(0x8000);
EsBatchCall :: struct {
	index :EsSyscallType,
	stopBatchIfError :bool,
	using _ : struct #raw_union {
		argument0 :uintptr,
		returnValue :uintptr,
	},

	argument1 :uintptr,
	argument2 :uintptr,
	argument3 :uintptr,
}

EsThreadInformation :: struct {
	handle :EsHandle,
	tid :uintptr,
}

EsProcessInformation :: struct {
	handle :EsHandle,
	pid :uintptr,
	mainThread :EsThreadInformation,
}

EsUniqueIdentifier :: struct {
	using _ : struct #raw_union {
		d :[16]u8,
	},

}

EsNodeInformation :: struct {
	handle :EsHandle,
	type :EsNodeType,
	using _ : struct #raw_union {
		fileSize :EsFileOffset,
		directoryChildren :EsFileOffset,
	},

}

EsDirectoryChild :: struct {
	name :[ES_MAX_DIRECTORY_CHILD_NAME_LENGTH]i8,
	nameBytes :uintptr,
	information :EsNodeInformation,
}

EsPoint :: struct {
	x :i32,
	y :i32,
}

EsRectangle :: struct {
	left :i32,
	right :i32,
	top :i32,
	bottom :i32,
}

EsRectangle16 :: struct {
	left :i16,
	right :i16,
	top :i16,
	bottom :i16,
}

EsColor :: struct {
	using _ : struct #raw_union {
		using _ : struct {
			blue :u8,
			green :u8,
			red :u8,
		},

		combined :u32,
	},

}

EsLinearBuffer :: struct {
	width :uintptr,
	height :uintptr,
	stride :uintptr,
	colorFormat :EsColorFormat,
	handle :EsHandle,
	flags :u32,
}

_EsRectangleAndColor :: struct {
	rectangle :EsRectangle,
	color :EsColor,
}

_EsStyledBoxData :: struct {
	backgroundColor :u32,
	borderColor :u32,
	borderSize :u8,
	cornerRadius :u8,
	roundedCornersToExclude :u8,
	ox :i32,
	oy :i32,
	width :i32,
	height :i32,
	clip :EsRectangle,
}

_EsInstanceCreateRemoteArguments :: struct {
	what :^i8,
	argument :^i8,
	whatBytes :uintptr,
	argumentBytes :uintptr,
	modalWindowParent :EsHandle,
	apiInstance :^rawptr,
}

_EsDrawSurfaceArguments :: struct {
	source :EsRectangle,
	destination :EsRectangle,
	border :EsRectangle,
	alpha :u16,
}

EsSpinlock :: struct {
	state :u8,
}

EsMutex :: struct {
	event :EsHandle,
	spinlock :EsSpinlock,
	state :u8,
	queued :u32,
}

EsCrashReason :: struct {
	errorCode :EsError,
}

EsProcessState :: struct {
	crashReason :EsCrashReason,
	creationArgument :EsGeneric,
	id :uintptr,
	executableState :uintptr,
	flags :u8,
}

EsIORequestProgress :: struct {
	accessed :EsFileOffset,
	progress :EsFileOffset,
	completed :bool,
	cancelled :bool,
	error :EsError,
}

EsClipboardHeader :: struct {
	customBytes :uintptr,
	format :EsClipboardFormat,
	textBytes :uintptr,
	unused :uintptr,
}

EsPainter :: struct {
	surface :EsHandle,
	clip :EsRectangle,
	offsetX :i32,
	offsetY :i32,
}

EsMessage :: struct {
	type :EsMessageType,
	_context :EsGeneric,
	using _ : struct #raw_union {
		_argument :^rawptr,
		mouseMoved : struct {
			oldPositionX :i32,
			newPositionX :i32,
			oldPositionY :i32,
			newPositionY :i32,
			newPositionXScreen :i32,
			newPositionYScreen :i32,
		},

		mouseDragged : struct {
			oldPositionX :i32,
			newPositionX :i32,
			oldPositionY :i32,
			newPositionY :i32,
			originalPositionX :i32,
			originalPositionY :i32,
		},

		mousePressed : struct {
			positionX :i32,
			positionY :i32,
			positionXScreen :i32,
			positionYScreen :i32,
			clickChainCount :u8,
			activationClick :u8,
			alt :u8,
			ctrl :u8,
			shift :u8,
		},

		keyboard : struct {
			scancode :u32,
			alt :u8,
			ctrl :u8,
			shift :u8,
			numpad :u8,
			notHandledBy :EsObject,
		},

		crash : struct {
			reason :EsCrashReason,
			process :EsHandle,
			processNameBuffer :EsHandle,
			processNameBytes :uintptr,
			pid :uintptr,
		},

		clipboard :EsClipboardHeader,
		receive : struct {
			buffer :EsHandle,
			bytes :uintptr,
		},

		animate : struct {
			deltaMcs :i64,
			waitMcs :i64,
			complete :bool,
		},

		systemConstantUpdated : struct {
			index :uintptr,
			newValue :u64,
		},

		desktopExecute : struct {
			whatBuffer :EsHandle,
			argumentBuffer :EsHandle,
			mailslot :EsHandle,
			whatBytes :uintptr,
			argumentBytes :uintptr,
			modalWindowParent :u64,
		},

		dockedWindowCreate : struct {
			pipe :EsHandle,
		},

		taskbar : struct {
			id :u64,
			buffer :EsHandle,
			bytes :uintptr,
		},

		windowResized : struct {
			content :EsRectangle,
		},

		painter :^EsPainter,
		measure : struct {
			width :i32,
			height :i32,
		},

		child :EsObject,
		size : struct {
			width :i32,
			height :i32,
		},

		hitTest : struct {
			x :i32,
			y :i32,
			inside :bool,
		},

		zOrder : struct {
			index :uintptr,
			child :^EsElement,
		},

		scrollbarMoved : struct {
			scroll :i32,
		},

		ensureVisible : struct {
			child :^EsElement,
		},

		cursorStyle :EsCursorStyle,
		getItemContent : struct {
			mask :u32,
			index :EsListViewIndex,
			column :EsListViewIndex,
			group :EsListViewIndex,
			text :^i8,
			textBytes :uintptr,
			iconHash :u32,
			iconWidth :u16,
			iconHeight :u16,
			indentation :u16,
			spaceAfterIcon :u16,
		},

		accessItemState : struct {
			mask :u32,
			state :u32,
			iIndexFrom :EsListViewIndex,
			eIndexTo :EsListViewIndex,
			group :EsListViewIndex,
		},

		measureItemHeight : struct {
			iIndexFrom :EsListViewIndex,
			eIndexTo :EsListViewIndex,
			group :EsListViewIndex,
			height :i32,
		},

		layoutItem : struct {
			index :EsListViewIndex,
			group :EsListViewIndex,
			knownIndex :EsListViewIndex,
			knownGroup :EsListViewIndex,
			bounds :EsRectangle,
		},

		toggleItemDisclosure : struct {
			index :EsListViewIndex,
			group :EsListViewIndex,
		},

		findItem : struct {
			type :u8,
			backwards :u8,
			inclusive :bool,
			indexFrom :EsListViewIndex,
			groupFrom :EsListViewIndex,
			foundIndex :EsListViewIndex,
			foundGroup :EsListViewIndex,
			using _ : struct #raw_union {
				using _ : struct {
					prefix :^i8,
					prefixBytes :uintptr,
				},

				using _ : struct {
					yPosition :i32,
					yPositionOfIndexFrom :i32,
					offsetIntoItem :i32,
				},

			},

		},

		listViewColumn : struct {
			index :EsListViewIndex,
			descending :bool,
		},

		setItemVisibility : struct {
			index :EsListViewIndex,
			group :EsListViewIndex,
			visible :bool,
		},

		setItemPosition : struct {
			index :EsListViewIndex,
			group :EsListViewIndex,
			bounds :EsRectangle,
		},

		listViewPaint : struct {
			surface :EsHandle,
			bounds :EsRectangle,
			clip :EsRectangle,
			index :EsListViewIndex,
			group :EsListViewIndex,
			column :EsListViewIndex,
			_internal :^rawptr,
		},

	},

}

EsDebuggerMessage :: struct {
	process :EsHandle,
	reason :EsCrashReason,
}

EsDriveInformation :: struct {
	name :[64]i8,
	nameBytes :uintptr,
	mountpoint :[256]i8,
	mountpointBytes :uintptr,
}

EsSnapshotProcessesItem :: struct {
	pid :i64,
	memoryUsage :i64,
	cpuTimeSlices :i64,
	name :[ES_SNAPSHOT_MAX_PROCESS_NAME_LENGTH]i8,
	nameLength :uintptr,
	internal :u64,
}

EsSystemInformation :: struct {
	processCount :uintptr,
	threadCount :uintptr,
	handleCount :uintptr,
	commitLimit :uintptr,
	commit :uintptr,
	countZeroedPages :uintptr,
	countFreePages :uintptr,
	countStandbyPages :uintptr,
	countModifiedPages :uintptr,
	countActivePages :uintptr,
	coreHeapSize :uintptr,
	coreHeapAllocations :uintptr,
	fixedHeapSize :uintptr,
	fixedHeapAllocations :uintptr,
	coreRegions :uintptr,
	kernelRegions :uintptr,
}

EsSnapshotProcesses :: struct {
	count :uintptr,
	processes :[]EsSnapshotProcessesItem,
}

_EsPOSIXSyscall :: struct {
	index :int,
	arguments :[7]int,
}

EsProcessCreationArguments :: struct {
	executablePath :^i8,
	executablePathBytes :uintptr,
	environmentBlock :^rawptr,
	environmentBlockBytes :uintptr,
	creationArgument :EsGeneric,
	permissions :u64,
}

_EsUserLoginArguments :: struct {
	name :^i8,
	nameBytes :uintptr,
	home :^i8,
	homeBytes :uintptr,
}

EsInstance :: struct {
	_private :^rawptr,
}

EsListViewColumn :: struct {
	title :^i8,
	titleBytes :uintptr,
	width :i32,
	minimumWidth :i32,
	flags :u32,
}

EsListViewStyle :: struct {
	flags :u32,
	fixedWidth :i32,
	fixedHeight :i32,
	groupHeaderHeight :i32,
	gapX :i32,
	gapY :i32,
	margin :EsRectangle16,
	columns :^EsListViewColumn,
	columnCount :uintptr,
	emptyMessage :^i8,
	emptyMessageBytes :uintptr,
}

EsBatch :: inline proc (calls :^EsBatchCall, count :uintptr){  ((proc (^EsBatchCall, uintptr))(rawptr(uintptr(0x1000 + 0 * size_of(int)))))(calls, count); }
EsProcessCreate :: inline proc (executablePath :^i8, executablePathLength :uintptr, information :^EsProcessInformation, argument :EsGeneric) -> EsError{ return ((proc (^i8, uintptr, ^EsProcessInformation, EsGeneric) -> EsError)(rawptr(uintptr(0x1000 + 1 * size_of(int)))))(executablePath, executablePathLength, information, argument); }
EsThreadCreate :: inline proc (entryFunction :EsThreadEntryFunction, information :^EsThreadInformation, argument :EsGeneric) -> EsError{ return ((proc (EsThreadEntryFunction, ^EsThreadInformation, EsGeneric) -> EsError)(rawptr(uintptr(0x1000 + 2 * size_of(int)))))(entryFunction, information, argument); }
EsSurfaceCreate :: inline proc (width :uintptr, height :uintptr, flags :u32) -> EsHandle{ return ((proc (uintptr, uintptr, u32) -> EsHandle)(rawptr(uintptr(0x1000 + 3 * size_of(int)))))(width, height, flags); }
EsEventCreate :: inline proc (autoReset :bool) -> EsHandle{ return ((proc (bool) -> EsHandle)(rawptr(uintptr(0x1000 + 4 * size_of(int)))))(autoReset); }
EsThreadLocalStorageSetAddress :: inline proc (address :^rawptr){  ((proc (^rawptr))(rawptr(uintptr(0x1000 + 5 * size_of(int)))))(address); }
EsConstantBufferRead :: inline proc (constantBuffer :EsHandle, output :^rawptr){  ((proc (EsHandle, ^rawptr))(rawptr(uintptr(0x1000 + 6 * size_of(int)))))(constantBuffer, output); }
EsConstantBufferShare :: inline proc (constantBuffer :EsHandle, targetProcess :EsHandle) -> EsHandle{ return ((proc (EsHandle, EsHandle) -> EsHandle)(rawptr(uintptr(0x1000 + 7 * size_of(int)))))(constantBuffer, targetProcess); }
EsConstantBufferCreate :: inline proc (data :^rawptr, dataBytes :uintptr, targetProcess :EsHandle) -> EsHandle{ return ((proc (^rawptr, uintptr, EsHandle) -> EsHandle)(rawptr(uintptr(0x1000 + 8 * size_of(int)))))(data, dataBytes, targetProcess); }
EsProcessOpen :: inline proc (pid :u64) -> EsHandle{ return ((proc (u64) -> EsHandle)(rawptr(uintptr(0x1000 + 9 * size_of(int)))))(pid); }
EsHandleClose :: inline proc (handle :EsHandle) -> EsError{ return ((proc (EsHandle) -> EsError)(rawptr(uintptr(0x1000 + 10 * size_of(int)))))(handle); }
EsTakeSystemSnapshot :: inline proc (type :i32, bufferSize :^uintptr) -> EsHandle{ return ((proc (i32, ^uintptr) -> EsHandle)(rawptr(uintptr(0x1000 + 11 * size_of(int)))))(type, bufferSize); }
EsGetSystemInformation :: inline proc (systemInformation :^EsSystemInformation){  ((proc (^EsSystemInformation))(rawptr(uintptr(0x1000 + 12 * size_of(int)))))(systemInformation); }
EsNodeOpen :: inline proc (path :^i8, pathLength :uintptr, flags :u64, information :^EsNodeInformation) -> EsError{ return ((proc (^i8, uintptr, u64, ^EsNodeInformation) -> EsError)(rawptr(uintptr(0x1000 + 13 * size_of(int)))))(path, pathLength, flags, information); }
EsNodeFindUniqueName :: inline proc (buffer :^i8, originalBytes :uintptr, bufferBytes :uintptr) -> uintptr{ return ((proc (^i8, uintptr, uintptr) -> uintptr)(rawptr(uintptr(0x1000 + 14 * size_of(int)))))(buffer, originalBytes, bufferBytes); }
EsFileReadAll :: inline proc (filePath :^i8, filePathLength :uintptr, fileSize :^uintptr){  ((proc (^i8, uintptr, ^uintptr))(rawptr(uintptr(0x1000 + 15 * size_of(int)))))(filePath, filePathLength, fileSize); }
EsFileReadSync :: inline proc (file :EsHandle, offset :EsFileOffset, size :uintptr, buffer :^rawptr) -> uintptr{ return ((proc (EsHandle, EsFileOffset, uintptr, ^rawptr) -> uintptr)(rawptr(uintptr(0x1000 + 16 * size_of(int)))))(file, offset, size, buffer); }
EsFileWriteSync :: inline proc (file :EsHandle, offset :EsFileOffset, size :uintptr, buffer :^rawptr) -> uintptr{ return ((proc (EsHandle, EsFileOffset, uintptr, ^rawptr) -> uintptr)(rawptr(uintptr(0x1000 + 17 * size_of(int)))))(file, offset, size, buffer); }
EsFileResize :: inline proc (file :EsHandle, newSize :EsFileOffset) -> EsError{ return ((proc (EsHandle, EsFileOffset) -> EsError)(rawptr(uintptr(0x1000 + 18 * size_of(int)))))(file, newSize); }
EsNodeRefreshInformation :: inline proc (information :^EsNodeInformation){  ((proc (^EsNodeInformation))(rawptr(uintptr(0x1000 + 19 * size_of(int)))))(information); }
EsDirectoryEnumerateChildren :: inline proc (directory :EsHandle, buffer :^EsDirectoryChild, bufferCount :uintptr) -> int{ return ((proc (EsHandle, ^EsDirectoryChild, uintptr) -> int)(rawptr(uintptr(0x1000 + 20 * size_of(int)))))(directory, buffer, bufferCount); }
EsNodeDelete :: inline proc (node :EsHandle) -> EsError{ return ((proc (EsHandle) -> EsError)(rawptr(uintptr(0x1000 + 21 * size_of(int)))))(node); }
EsNodeMove :: inline proc (node :EsHandle, newDirectory :EsHandle, newName :^i8, newNameLength :uintptr) -> EsError{ return ((proc (EsHandle, EsHandle, ^i8, uintptr) -> EsError)(rawptr(uintptr(0x1000 + 22 * size_of(int)))))(node, newDirectory, newName, newNameLength); }
EsThreadTerminate :: inline proc (thread :EsHandle){  ((proc (EsHandle))(rawptr(uintptr(0x1000 + 23 * size_of(int)))))(thread); }
EsProcessTerminate :: inline proc (process :EsHandle, status :i32){  ((proc (EsHandle, i32))(rawptr(uintptr(0x1000 + 24 * size_of(int)))))(process, status); }
EsProcessTerminateCurrent :: inline proc (){  ((proc ())(rawptr(uintptr(0x1000 + 25 * size_of(int)))))(); }
EsProcessPause :: inline proc (process :EsHandle, resume :bool){  ((proc (EsHandle, bool))(rawptr(uintptr(0x1000 + 26 * size_of(int)))))(process, resume); }
EsProcessCrash :: inline proc (error :EsError, message :^i8, messageBytes :uintptr){  ((proc (EsError, ^i8, uintptr))(rawptr(uintptr(0x1000 + 27 * size_of(int)))))(error, message, messageBytes); }
EsThreadGetID :: inline proc (thread :EsHandle) -> uintptr{ return ((proc (EsHandle) -> uintptr)(rawptr(uintptr(0x1000 + 28 * size_of(int)))))(thread); }
EsProcessGetID :: inline proc (process :EsHandle) -> uintptr{ return ((proc (EsHandle) -> uintptr)(rawptr(uintptr(0x1000 + 29 * size_of(int)))))(process); }
EsSpinlockRelease :: inline proc (spinlock :^EsSpinlock){  ((proc (^EsSpinlock))(rawptr(uintptr(0x1000 + 30 * size_of(int)))))(spinlock); }
EsSpinlockAcquire :: inline proc (spinlock :^EsSpinlock){  ((proc (^EsSpinlock))(rawptr(uintptr(0x1000 + 31 * size_of(int)))))(spinlock); }
EsMutexRelease :: inline proc (mutex :^EsMutex){  ((proc (^EsMutex))(rawptr(uintptr(0x1000 + 32 * size_of(int)))))(mutex); }
EsMutexAcquire :: inline proc (mutex :^EsMutex){  ((proc (^EsMutex))(rawptr(uintptr(0x1000 + 33 * size_of(int)))))(mutex); }
EsMutexDestroy :: inline proc (mutex :^EsMutex){  ((proc (^EsMutex))(rawptr(uintptr(0x1000 + 34 * size_of(int)))))(mutex); }
EsSchedulerYield :: inline proc (){  ((proc ())(rawptr(uintptr(0x1000 + 35 * size_of(int)))))(); }
EsEventSet :: inline proc (event :EsHandle){  ((proc (EsHandle))(rawptr(uintptr(0x1000 + 36 * size_of(int)))))(event); }
EsEventReset :: inline proc (event :EsHandle){  ((proc (EsHandle))(rawptr(uintptr(0x1000 + 37 * size_of(int)))))(event); }
EsEventPoll :: inline proc (event :EsHandle) -> EsError{ return ((proc (EsHandle) -> EsError)(rawptr(uintptr(0x1000 + 38 * size_of(int)))))(event); }
EsWait :: inline proc (objects :^EsHandle, objectCount :uintptr, timeoutMs :uintptr) -> uintptr{ return ((proc (^EsHandle, uintptr, uintptr) -> uintptr)(rawptr(uintptr(0x1000 + 39 * size_of(int)))))(objects, objectCount, timeoutMs); }
EsSleep :: inline proc (milliseconds :u64){  ((proc (u64))(rawptr(uintptr(0x1000 + 40 * size_of(int)))))(milliseconds); }
EsMemoryOpen :: inline proc (size :uintptr, name :^i8, nameLength :uintptr, flags :u32) -> EsHandle{ return ((proc (uintptr, ^i8, uintptr, u32) -> EsHandle)(rawptr(uintptr(0x1000 + 41 * size_of(int)))))(size, name, nameLength, flags); }
EsMemoryShare :: inline proc (sharedMemoryRegion :EsHandle, targetProcess :EsHandle, readOnly :bool) -> EsHandle{ return ((proc (EsHandle, EsHandle, bool) -> EsHandle)(rawptr(uintptr(0x1000 + 42 * size_of(int)))))(sharedMemoryRegion, targetProcess, readOnly); }
EsObjectMap :: inline proc (object :EsHandle, offset :uintptr, size :uintptr, flags :u32){  ((proc (EsHandle, uintptr, uintptr, u32))(rawptr(uintptr(0x1000 + 43 * size_of(int)))))(object, offset, size, flags); }
EsMemoryAllocate :: inline proc (size :uintptr){  ((proc (uintptr))(rawptr(uintptr(0x1000 + 44 * size_of(int)))))(size); }
EsMemoryFree :: inline proc (address :^rawptr) -> EsError{ return ((proc (^rawptr) -> EsError)(rawptr(uintptr(0x1000 + 45 * size_of(int)))))(address); }
EsGetCreationArgument :: inline proc (object :EsHandle) -> EsGeneric{ return ((proc (EsHandle) -> EsGeneric)(rawptr(uintptr(0x1000 + 46 * size_of(int)))))(object); }
EsProcessGetState :: inline proc (process :EsHandle, state :^EsProcessState){  ((proc (EsHandle, ^EsProcessState))(rawptr(uintptr(0x1000 + 47 * size_of(int)))))(process, state); }
EsSurfaceGetLinearBuffer :: inline proc (surface :EsHandle, linearBuffer :^EsLinearBuffer){  ((proc (EsHandle, ^EsLinearBuffer))(rawptr(uintptr(0x1000 + 48 * size_of(int)))))(surface, linearBuffer); }
EsRectangleInvalidate :: inline proc (surface :EsHandle, rectangle :EsRectangle){  ((proc (EsHandle, EsRectangle))(rawptr(uintptr(0x1000 + 49 * size_of(int)))))(surface, rectangle); }
EsCopyToScreen :: inline proc (source :EsHandle, point :EsPoint, depth :u16){  ((proc (EsHandle, EsPoint, u16))(rawptr(uintptr(0x1000 + 50 * size_of(int)))))(source, point, depth); }
EsForceScreenUpdate :: inline proc (){  ((proc ())(rawptr(uintptr(0x1000 + 51 * size_of(int)))))(); }
EsDrawRectangle :: inline proc (surface :EsHandle, rectangle :EsRectangle, color :EsColor){  ((proc (EsHandle, EsRectangle, EsColor))(rawptr(uintptr(0x1000 + 52 * size_of(int)))))(surface, rectangle, color); }
EsDrawRectangleClipped :: inline proc (surface :EsHandle, rectangle :EsRectangle, color :EsColor, clipRegion :EsRectangle){  ((proc (EsHandle, EsRectangle, EsColor, EsRectangle))(rawptr(uintptr(0x1000 + 53 * size_of(int)))))(surface, rectangle, color, clipRegion); }
EsDrawSurfaceBlit :: inline proc (destination :EsHandle, source :EsHandle, destinationPoint :EsPoint){  ((proc (EsHandle, EsHandle, EsPoint))(rawptr(uintptr(0x1000 + 54 * size_of(int)))))(destination, source, destinationPoint); }
EsDrawSurface :: inline proc (destination :EsHandle, source :EsHandle, destinationRegion :EsRectangle, sourceRegion :EsRectangle, borderRegion :EsRectangle, mode :EsDrawMode, alpha :u16) -> EsError{ return ((proc (EsHandle, EsHandle, EsRectangle, EsRectangle, EsRectangle, EsDrawMode, u16) -> EsError)(rawptr(uintptr(0x1000 + 55 * size_of(int)))))(destination, source, destinationRegion, sourceRegion, borderRegion, mode, alpha); }
EsDrawSurfaceClipped :: inline proc (destination :EsHandle, source :EsHandle, destinationRegion :EsRectangle, sourceRegion :EsRectangle, borderRegion :EsRectangle, mode :EsDrawMode, alpha :u16, clipRegion :EsRectangle) -> EsError{ return ((proc (EsHandle, EsHandle, EsRectangle, EsRectangle, EsRectangle, EsDrawMode, u16, EsRectangle) -> EsError)(rawptr(uintptr(0x1000 + 56 * size_of(int)))))(destination, source, destinationRegion, sourceRegion, borderRegion, mode, alpha, clipRegion); }
EsDrawBitmap :: inline proc (destination :EsHandle, destinationPoint :EsPoint, bitmap :^rawptr, width :uintptr, height :uintptr, stride :uintptr, colorFormat :EsColorFormat){  ((proc (EsHandle, EsPoint, ^rawptr, uintptr, uintptr, uintptr, EsColorFormat))(rawptr(uintptr(0x1000 + 57 * size_of(int)))))(destination, destinationPoint, bitmap, width, height, stride, colorFormat); }
EsSurfaceClearInvalidatedRegion :: inline proc (surface :EsHandle){  ((proc (EsHandle))(rawptr(uintptr(0x1000 + 58 * size_of(int)))))(surface); }
EsRectangleClip :: inline proc (parent :EsRectangle, rectangle :EsRectangle, output :^EsRectangle) -> bool{ return ((proc (EsRectangle, EsRectangle, ^EsRectangle) -> bool)(rawptr(uintptr(0x1000 + 59 * size_of(int)))))(parent, rectangle, output); }
EsDrawBox :: inline proc (surface :EsHandle, rectangle :EsRectangle, style :u8, color :u32, clipRegion :EsRectangle){  ((proc (EsHandle, EsRectangle, u8, u32, EsRectangle))(rawptr(uintptr(0x1000 + 60 * size_of(int)))))(surface, rectangle, style, color, clipRegion); }
EsRedrawAll :: inline proc (){  ((proc ())(rawptr(uintptr(0x1000 + 61 * size_of(int)))))(); }
EsMessagePost :: inline proc (message :^EsMessage) -> EsError{ return ((proc (^EsMessage) -> EsError)(rawptr(uintptr(0x1000 + 62 * size_of(int)))))(message); }
EsMessagePostRemote :: inline proc (process :EsHandle, message :^EsMessage) -> EsError{ return ((proc (EsHandle, ^EsMessage) -> EsError)(rawptr(uintptr(0x1000 + 63 * size_of(int)))))(process, message); }
EsExtractArguments :: inline proc (string :^i8, bytes :uintptr, delimiterByte :u8, replacementDelimiter :u8, argvAllocated :uintptr, argv :^^i8, argc :^uintptr) -> bool{ return ((proc (^i8, uintptr, u8, u8, uintptr, ^^i8, ^uintptr) -> bool)(rawptr(uintptr(0x1000 + 64 * size_of(int)))))(string, bytes, delimiterByte, replacementDelimiter, argvAllocated, argv, argc); }
EsCStringLength :: inline proc (string :^i8) -> uintptr{ return ((proc (^i8) -> uintptr)(rawptr(uintptr(0x1000 + 65 * size_of(int)))))(string); }
EsStringLength :: inline proc (string :^i8, end :u8) -> uintptr{ return ((proc (^i8, u8) -> uintptr)(rawptr(uintptr(0x1000 + 66 * size_of(int)))))(string, end); }
EsMemoryCopy :: inline proc (destination :^rawptr, source :^rawptr, bytes :uintptr){  ((proc (^rawptr, ^rawptr, uintptr))(rawptr(uintptr(0x1000 + 67 * size_of(int)))))(destination, source, bytes); }
EsMemoryMove :: inline proc (_start :^rawptr, _end :^rawptr, amount :int, zeroEmptySpace :bool){  ((proc (^rawptr, ^rawptr, int, bool))(rawptr(uintptr(0x1000 + 68 * size_of(int)))))(_start, _end, amount, zeroEmptySpace); }
EsMemoryCopyReverse :: inline proc (_destination :^rawptr, _source :^rawptr, bytes :uintptr){  ((proc (^rawptr, ^rawptr, uintptr))(rawptr(uintptr(0x1000 + 69 * size_of(int)))))(_destination, _source, bytes); }
EsMemoryZero :: inline proc (destination :^rawptr, bytes :uintptr){  ((proc (^rawptr, uintptr))(rawptr(uintptr(0x1000 + 70 * size_of(int)))))(destination, bytes); }
EsMemoryCompare :: inline proc (a :^rawptr, b :^rawptr, bytes :uintptr) -> i32{ return ((proc (^rawptr, ^rawptr, uintptr) -> i32)(rawptr(uintptr(0x1000 + 71 * size_of(int)))))(a, b, bytes); }
EsMemorySumBytes :: inline proc (data :^u8, bytes :uintptr) -> u8{ return ((proc (^u8, uintptr) -> u8)(rawptr(uintptr(0x1000 + 72 * size_of(int)))))(data, bytes); }
EsPrintDirect :: inline proc (string :^i8, stringLength :uintptr){  ((proc (^i8, uintptr))(rawptr(uintptr(0x1000 + 73 * size_of(int)))))(string, stringLength); }
EsStringFormat :: inline proc (buffer :^i8, bufferLength :uintptr, format :^i8, args : ..any) -> uintptr{ return ((proc (^i8, uintptr, ^i8, ..any) -> uintptr)(rawptr(uintptr(0x1000 + 74 * size_of(int)))))(buffer, bufferLength, format, ); }
EsStringFormatAppend :: inline proc (buffer :^i8, bufferLength :uintptr, bufferPosition :^uintptr, format :^i8, args : ..any){  ((proc (^i8, uintptr, ^uintptr, ^i8, ..any))(rawptr(uintptr(0x1000 + 75 * size_of(int)))))(buffer, bufferLength, bufferPosition, format, ); }
EsPrintHelloWorld :: inline proc (){  ((proc ())(rawptr(uintptr(0x1000 + 76 * size_of(int)))))(); }
EsGetRandomByte :: inline proc () -> u8{ return ((proc () -> u8)(rawptr(uintptr(0x1000 + 77 * size_of(int)))))(); }
EsSort :: inline proc (_base :^rawptr, nmemb :uintptr, size :uintptr, compar :EsComparisonCallbackFunction, argument :EsGeneric){  ((proc (^rawptr, uintptr, uintptr, EsComparisonCallbackFunction, EsGeneric))(rawptr(uintptr(0x1000 + 78 * size_of(int)))))(_base, nmemb, size, compar, argument); }
EsSortWithSwapCallback :: inline proc (_base :^rawptr, nmemb :uintptr, size :uintptr, compar :EsComparisonCallbackFunction, argument :EsGeneric, swap :EsSwapCallbackFunction){  ((proc (^rawptr, uintptr, uintptr, EsComparisonCallbackFunction, EsGeneric, EsSwapCallbackFunction))(rawptr(uintptr(0x1000 + 79 * size_of(int)))))(_base, nmemb, size, compar, argument, swap); }
EsStringCompare :: inline proc (s1 :^i8, s2 :^i8, length1 :uintptr, length2 :uintptr) -> i32{ return ((proc (^i8, ^i8, uintptr, uintptr) -> i32)(rawptr(uintptr(0x1000 + 80 * size_of(int)))))(s1, s2, length1, length2); }
EsIntegerParse :: inline proc (text :^i8, bytes :uintptr) -> i64{ return ((proc (^i8, uintptr) -> i64)(rawptr(uintptr(0x1000 + 81 * size_of(int)))))(text, bytes); }
EsCRTmemset :: inline proc (s :^rawptr, c :i32, n :uintptr){  ((proc (^rawptr, i32, uintptr))(rawptr(uintptr(0x1000 + 82 * size_of(int)))))(s, c, n); }
EsCRTmemcpy :: inline proc (dest :^rawptr, src :^rawptr, n :uintptr){  ((proc (^rawptr, ^rawptr, uintptr))(rawptr(uintptr(0x1000 + 83 * size_of(int)))))(dest, src, n); }
EsCRTmemmove :: inline proc (dest :^rawptr, src :^rawptr, n :uintptr){  ((proc (^rawptr, ^rawptr, uintptr))(rawptr(uintptr(0x1000 + 84 * size_of(int)))))(dest, src, n); }
EsCRTstrlen :: inline proc (s :^i8) -> uintptr{ return ((proc (^i8) -> uintptr)(rawptr(uintptr(0x1000 + 85 * size_of(int)))))(s); }
EsCRTstrnlen :: inline proc (s :^i8, maxlen :uintptr) -> uintptr{ return ((proc (^i8, uintptr) -> uintptr)(rawptr(uintptr(0x1000 + 86 * size_of(int)))))(s, maxlen); }
EsCRTmalloc :: inline proc (size :uintptr){  ((proc (uintptr))(rawptr(uintptr(0x1000 + 87 * size_of(int)))))(size); }
EsCRTcalloc :: inline proc (num :uintptr, size :uintptr){  ((proc (uintptr, uintptr))(rawptr(uintptr(0x1000 + 88 * size_of(int)))))(num, size); }
EsCRTfree :: inline proc (ptr :^rawptr){  ((proc (^rawptr))(rawptr(uintptr(0x1000 + 89 * size_of(int)))))(ptr); }
EsCRTabs :: inline proc (n :i32) -> i32{ return ((proc (i32) -> i32)(rawptr(uintptr(0x1000 + 90 * size_of(int)))))(n); }
EsCRTrealloc :: inline proc (ptr :^rawptr, size :uintptr){  ((proc (^rawptr, uintptr))(rawptr(uintptr(0x1000 + 91 * size_of(int)))))(ptr, size); }
EsCRTgetenv :: inline proc (name :^i8) -> ^i8{ return ((proc (^i8) -> ^i8)(rawptr(uintptr(0x1000 + 92 * size_of(int)))))(name); }
EsCRTstrncmp :: inline proc (s1 :^i8, s2 :^i8, n :uintptr) -> i32{ return ((proc (^i8, ^i8, uintptr) -> i32)(rawptr(uintptr(0x1000 + 93 * size_of(int)))))(s1, s2, n); }
EsCRTmemcmp :: inline proc (s1 :^rawptr, s2 :^rawptr, n :uintptr) -> i32{ return ((proc (^rawptr, ^rawptr, uintptr) -> i32)(rawptr(uintptr(0x1000 + 94 * size_of(int)))))(s1, s2, n); }
EsCRTqsort :: inline proc (_base :^rawptr, nmemb :uintptr, size :uintptr, compar :EsCRTComparisonCallback){  ((proc (^rawptr, uintptr, uintptr, EsCRTComparisonCallback))(rawptr(uintptr(0x1000 + 95 * size_of(int)))))(_base, nmemb, size, compar); }
EsCRTstrcmp :: inline proc (s1 :^i8, s2 :^i8) -> i32{ return ((proc (^i8, ^i8) -> i32)(rawptr(uintptr(0x1000 + 96 * size_of(int)))))(s1, s2); }
EsCRTstrstr :: inline proc (haystack :^i8, needle :^i8) -> ^i8{ return ((proc (^i8, ^i8) -> ^i8)(rawptr(uintptr(0x1000 + 97 * size_of(int)))))(haystack, needle); }
EsCRTstrcpy :: inline proc (dest :^i8, src :^i8) -> ^i8{ return ((proc (^i8, ^i8) -> ^i8)(rawptr(uintptr(0x1000 + 98 * size_of(int)))))(dest, src); }
EsCRTisalpha :: inline proc (c :i32) -> i32{ return ((proc (i32) -> i32)(rawptr(uintptr(0x1000 + 99 * size_of(int)))))(c); }
EsCRTmemchr :: inline proc (_s :^rawptr, _c :i32, n :uintptr){  ((proc (^rawptr, i32, uintptr))(rawptr(uintptr(0x1000 + 100 * size_of(int)))))(_s, _c, n); }
EsCRTisdigit :: inline proc (c :i32) -> i32{ return ((proc (i32) -> i32)(rawptr(uintptr(0x1000 + 101 * size_of(int)))))(c); }
EsCRTstrcat :: inline proc (dest :^i8, src :^i8) -> ^i8{ return ((proc (^i8, ^i8) -> ^i8)(rawptr(uintptr(0x1000 + 102 * size_of(int)))))(dest, src); }
EsCRTtolower :: inline proc (c :i32) -> i32{ return ((proc (i32) -> i32)(rawptr(uintptr(0x1000 + 103 * size_of(int)))))(c); }
EsCRTstrncpy :: inline proc (dest :^i8, src :^i8, n :uintptr) -> ^i8{ return ((proc (^i8, ^i8, uintptr) -> ^i8)(rawptr(uintptr(0x1000 + 104 * size_of(int)))))(dest, src, n); }
EsCRTstrtoul :: inline proc (nptr :^i8, endptr :^^i8, base :i32) -> u64{ return ((proc (^i8, ^^i8, i32) -> u64)(rawptr(uintptr(0x1000 + 105 * size_of(int)))))(nptr, endptr, base); }
EsExecute :: inline proc (what :^i8, whatBytes :uintptr, argument :^i8, argumentBytes :uintptr){  ((proc (^i8, uintptr, ^i8, uintptr))(rawptr(uintptr(0x1000 + 106 * size_of(int)))))(what, whatBytes, argument, argumentBytes); }
EsAbort :: inline proc (){  ((proc ())(rawptr(uintptr(0x1000 + 107 * size_of(int)))))(); }
EsMailslotSendData :: inline proc (mailslot :EsHandle, data :^rawptr, bytes :uintptr) -> bool{ return ((proc (EsHandle, ^rawptr, uintptr) -> bool)(rawptr(uintptr(0x1000 + 108 * size_of(int)))))(mailslot, data, bytes); }
EsCRTfloorf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 109 * size_of(int)))))(x); }
EsCRTceilf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 110 * size_of(int)))))(x); }
EsCRTsinf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 111 * size_of(int)))))(x); }
EsCRTcosf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 112 * size_of(int)))))(x); }
EsCRTatan2f :: inline proc (y :f32, x :f32) -> f32{ return ((proc (f32, f32) -> f32)(rawptr(uintptr(0x1000 + 113 * size_of(int)))))(y, x); }
EsCRTfmodf :: inline proc (x :f32, y :f32) -> f32{ return ((proc (f32, f32) -> f32)(rawptr(uintptr(0x1000 + 114 * size_of(int)))))(x, y); }
EsCRTacosf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 115 * size_of(int)))))(x); }
EsCRTasinf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 116 * size_of(int)))))(x); }
EsCRTatanf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 117 * size_of(int)))))(x); }
EsRandomSeed :: inline proc (x :u64){  ((proc (u64))(rawptr(uintptr(0x1000 + 118 * size_of(int)))))(x); }
EsCRTsqrtf :: inline proc (x :f32) -> f32{ return ((proc (f32) -> f32)(rawptr(uintptr(0x1000 + 119 * size_of(int)))))(x); }
EsCRTsqrtl :: inline proc (x :EsLongDouble) -> EsLongDouble{ return ((proc (EsLongDouble) -> EsLongDouble)(rawptr(uintptr(0x1000 + 120 * size_of(int)))))(x); }
EsCRTfabsl :: inline proc (x :EsLongDouble) -> EsLongDouble{ return ((proc (EsLongDouble) -> EsLongDouble)(rawptr(uintptr(0x1000 + 121 * size_of(int)))))(x); }
_EsSyscall :: inline proc (a :uintptr, b :uintptr, c :uintptr, d :uintptr, e :uintptr, f :uintptr) -> uintptr{ return ((proc (uintptr, uintptr, uintptr, uintptr, uintptr, uintptr) -> uintptr)(rawptr(uintptr(0x1000 + 122 * size_of(int)))))(a, b, c, d, e, f); }
EsProcessorReadTimeStamp :: inline proc () -> u64{ return ((proc () -> u64)(rawptr(uintptr(0x1000 + 123 * size_of(int)))))(); }
EsHeapAllocate :: inline proc (size :uintptr, zeroMemory :bool){  ((proc (uintptr, bool))(rawptr(uintptr(0x1000 + 124 * size_of(int)))))(size, zeroMemory); }
EsHeapFree :: inline proc (address :^rawptr){  ((proc (^rawptr))(rawptr(uintptr(0x1000 + 125 * size_of(int)))))(address); }
EsPrint :: inline proc (format :^i8, args : ..any){  ((proc (^i8, ..any))(rawptr(uintptr(0x1000 + 126 * size_of(int)))))(format, ); }
EsMemoryFill :: inline proc (from :^rawptr, to :^rawptr, byte :u8){  ((proc (^rawptr, ^rawptr, u8))(rawptr(uintptr(0x1000 + 127 * size_of(int)))))(from, to, byte); }
EsInitialiseCStandardLibrary :: inline proc (argc :^i32, argv :^^^i8){  ((proc (^i32, ^^^i8))(rawptr(uintptr(0x1000 + 128 * size_of(int)))))(argc, argv); }
EsMakeLinuxSystemCall2 :: inline proc (n :int, a1 :int, a2 :int, a3 :int, a4 :int, a5 :int, a6 :int) -> int{ return ((proc (int, int, int, int, int, int, int) -> int)(rawptr(uintptr(0x1000 + 129 * size_of(int)))))(n, a1, a2, a3, a4, a5, a6); }
EsProcessCreate2 :: inline proc (arguments :^EsProcessCreationArguments, information :^EsProcessInformation) -> EsError{ return ((proc (^EsProcessCreationArguments, ^EsProcessInformation) -> EsError)(rawptr(uintptr(0x1000 + 130 * size_of(int)))))(arguments, information); }
EsCRTatoi :: inline proc (string :^i8) -> i32{ return ((proc (^i8) -> i32)(rawptr(uintptr(0x1000 + 131 * size_of(int)))))(string); }
EsProcessGetExitStatus :: inline proc (process :EsHandle) -> i32{ return ((proc (EsHandle) -> i32)(rawptr(uintptr(0x1000 + 132 * size_of(int)))))(process); }
EsSurfaceReset :: inline proc (surface :EsHandle){  ((proc (EsHandle))(rawptr(uintptr(0x1000 + 133 * size_of(int)))))(surface); }
EsTimerCreate :: inline proc () -> EsHandle{ return ((proc () -> EsHandle)(rawptr(uintptr(0x1000 + 134 * size_of(int)))))(); }
EsTimerSet :: inline proc (handle :EsHandle, afterMs :u64, object :EsObject, argument :EsGeneric){  ((proc (EsHandle, u64, EsObject, EsGeneric))(rawptr(uintptr(0x1000 + 135 * size_of(int)))))(handle, afterMs, object, argument); }
EsFileWriteAll :: inline proc (filePath :^i8, filePathLength :uintptr, data :^rawptr, fileSize :uintptr) -> EsError{ return ((proc (^i8, uintptr, ^rawptr, uintptr) -> EsError)(rawptr(uintptr(0x1000 + 136 * size_of(int)))))(filePath, filePathLength, data, fileSize); }
EsUserGetHomeFolder :: inline proc (buffer :^i8, bufferBytes :uintptr) -> uintptr{ return ((proc (^i8, uintptr) -> uintptr)(rawptr(uintptr(0x1000 + 137 * size_of(int)))))(buffer, bufferBytes); }
EsAssert :: inline proc (expression :bool, failureMessage :^i8){  ((proc (bool, ^i8))(rawptr(uintptr(0x1000 + 138 * size_of(int)))))(expression, failureMessage); }
EsResizeArray :: inline proc (array :^^rawptr, allocated :^uintptr, needed :uintptr, itemSize :uintptr){  ((proc (^^rawptr, ^uintptr, uintptr, uintptr))(rawptr(uintptr(0x1000 + 139 * size_of(int)))))(array, allocated, needed, itemSize); }
EsMessageLoopEnter :: inline proc (callback :EsMessageCallbackFunction){  ((proc (EsMessageCallbackFunction))(rawptr(uintptr(0x1000 + 140 * size_of(int)))))(callback); }
_EsInstanceCreate :: inline proc (bytes :uintptr) -> ^EsInstance{ return ((proc (uintptr) -> ^EsInstance)(rawptr(uintptr(0x1000 + 141 * size_of(int)))))(bytes); }
EsMouseGetPosition :: inline proc (relativeWindow :^EsElement) -> EsPoint{ return ((proc (^EsElement) -> EsPoint)(rawptr(uintptr(0x1000 + 142 * size_of(int)))))(relativeWindow); }
EsMouseSetPosition :: inline proc (relativeWindow :^EsElement, x :i32, y :i32){  ((proc (^EsElement, i32, i32))(rawptr(uintptr(0x1000 + 143 * size_of(int)))))(relativeWindow, x, y); }
EsNewWindow :: inline proc (instance :^EsInstance, style :EsWindowStyle) -> ^EsElement{ return ((proc (^EsInstance, EsWindowStyle) -> ^EsElement)(rawptr(uintptr(0x1000 + 144 * size_of(int)))))(instance, style); }
EsNewPanel :: inline proc (parent :^EsElement, style :EsData, flags :u64) -> ^EsElement{ return ((proc (^EsElement, EsData, u64) -> ^EsElement)(rawptr(uintptr(0x1000 + 145 * size_of(int)))))(parent, style, flags); }
EsNewScrollbar :: inline proc (parent :^EsElement, flags :u64, userCallback :EsUICallbackFunction, _context :EsGeneric) -> ^EsElement{ return ((proc (^EsElement, u64, EsUICallbackFunction, EsGeneric) -> ^EsElement)(rawptr(uintptr(0x1000 + 146 * size_of(int)))))(parent, flags, userCallback, _context); }
EsNewButton :: inline proc (parent :^EsElement, label :^i8, labelBytes :int, flags :u64, userCallback :EsUICallbackFunction, _context :EsGeneric) -> ^EsElement{ return ((proc (^EsElement, ^i8, int, u64, EsUICallbackFunction, EsGeneric) -> ^EsElement)(rawptr(uintptr(0x1000 + 147 * size_of(int)))))(parent, label, labelBytes, flags, userCallback, _context); }
EsNewTextbox :: inline proc (parent :^EsElement, flags :u64, userCallback :EsUICallbackFunction, _context :EsGeneric) -> ^EsElement{ return ((proc (^EsElement, u64, EsUICallbackFunction, EsGeneric) -> ^EsElement)(rawptr(uintptr(0x1000 + 148 * size_of(int)))))(parent, flags, userCallback, _context); }
EsNewNumericEntry :: inline proc (parent :^EsElement, flags :u64, userCallback :EsUICallbackFunction, _context :EsGeneric) -> ^EsElement{ return ((proc (^EsElement, u64, EsUICallbackFunction, EsGeneric) -> ^EsElement)(rawptr(uintptr(0x1000 + 149 * size_of(int)))))(parent, flags, userCallback, _context); }
EsNewListView :: inline proc (parent :^EsElement, flags :u64, style :^EsListViewStyle, userCallback :EsUICallbackFunction, _context :EsGeneric) -> ^EsElement{ return ((proc (^EsElement, u64, ^EsListViewStyle, EsUICallbackFunction, EsGeneric) -> ^EsElement)(rawptr(uintptr(0x1000 + 150 * size_of(int)))))(parent, flags, style, userCallback, _context); }
EsElementGetInstance :: inline proc (element :^EsElement) -> ^EsInstance{ return ((proc (^EsElement) -> ^EsInstance)(rawptr(uintptr(0x1000 + 151 * size_of(int)))))(element); }
EsElementFocus :: inline proc (element :^EsElement, ensureVisible :bool){  ((proc (^EsElement, bool))(rawptr(uintptr(0x1000 + 152 * size_of(int)))))(element, ensureVisible); }
EsScrollbarSetMeasurements :: inline proc (scrollbar :^EsElement, viewportSize :i32, contentSize :i32){  ((proc (^EsElement, i32, i32))(rawptr(uintptr(0x1000 + 153 * size_of(int)))))(scrollbar, viewportSize, contentSize); }
EsScrollbarSetPosition :: inline proc (scrollbar :^EsElement, position :f32, sendMovedMessage :bool, smoothScroll :bool){  ((proc (^EsElement, f32, bool, bool))(rawptr(uintptr(0x1000 + 154 * size_of(int)))))(scrollbar, position, sendMovedMessage, smoothScroll); }
EsWindowGetBounds :: inline proc (window :^EsElement, bounds :^EsRectangle){  ((proc (^EsElement, ^EsRectangle))(rawptr(uintptr(0x1000 + 155 * size_of(int)))))(window, bounds); }
EsListViewInsert :: inline proc (listView :^EsElement, group :EsListViewIndex, index :EsListViewIndex, count :uintptr){  ((proc (^EsElement, EsListViewIndex, EsListViewIndex, uintptr))(rawptr(uintptr(0x1000 + 156 * size_of(int)))))(listView, group, index, count); }
EsListViewInsertGroup :: inline proc (listView :^EsElement, group :EsListViewIndex){  ((proc (^EsElement, EsListViewIndex))(rawptr(uintptr(0x1000 + 157 * size_of(int)))))(listView, group); }
EsListViewRemove :: inline proc (listView :^EsElement, group :EsListViewIndex, index :EsListViewIndex, count :int, removedHeight :i32){  ((proc (^EsElement, EsListViewIndex, EsListViewIndex, int, i32))(rawptr(uintptr(0x1000 + 158 * size_of(int)))))(listView, group, index, count, removedHeight); }
EsListViewRemoveGroup :: inline proc (listView :^EsElement, group :EsListViewIndex){  ((proc (^EsElement, EsListViewIndex))(rawptr(uintptr(0x1000 + 159 * size_of(int)))))(listView, group); }
EsListViewInvalidate :: inline proc (listView :^EsElement, deltaHeight :i32, recalculateHeight :bool){  ((proc (^EsElement, i32, bool))(rawptr(uintptr(0x1000 + 160 * size_of(int)))))(listView, deltaHeight, recalculateHeight); }
EsListViewEnsureVisible :: inline proc (listView :^EsElement, group :EsListViewIndex, index :EsListViewIndex){  ((proc (^EsElement, EsListViewIndex, EsListViewIndex))(rawptr(uintptr(0x1000 + 161 * size_of(int)))))(listView, group, index); }
EsListViewResetSearchBuffer :: inline proc (object :^EsElement){  ((proc (^EsElement))(rawptr(uintptr(0x1000 + 162 * size_of(int)))))(object); }
EsDataParse :: inline proc (cFormat :^i8, args : ..any) -> EsData{ return ((proc (^i8, ..any) -> EsData)(rawptr(uintptr(0x1000 + 163 * size_of(int)))))(cFormat, ); }
EsDataNone :: inline proc () -> EsData{ return ((proc () -> EsData)(rawptr(uintptr(0x1000 + 164 * size_of(int)))))(); }

//////////////////////////////////////////////////////

Handle :: distinct i32;
Errno  :: distinct i32;

INVALID_HANDLE :: ~Handle(0);

stdin:  Handle = 0;
stdout: Handle = 1;
stderr: Handle = 2;

O_RDONLY   :: 0x00000;
O_WRONLY   :: 0x00001;
O_RDWR     :: 0x00002;
O_CREATE   :: 0x00040;
O_EXCL     :: 0x00080;
O_NOCTTY   :: 0x00100;
O_TRUNC    :: 0x00200;
O_NONBLOCK :: 0x00800;
O_APPEND   :: 0x00400;
O_SYNC     :: 0x01000;
O_ASYNC    :: 0x02000;
O_CLOEXEC  :: 0x80000;

ERROR_UNSUPPORTED :: 1;

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	return -1, ERROR_UNSUPPORTED;
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	return -1, ERROR_UNSUPPORTED;
}

open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Errno) {
	return -1, ERROR_UNSUPPORTED;
}

close :: proc(fd: Handle) -> Errno {
	return ERROR_UNSUPPORTED;
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	return 0, ERROR_UNSUPPORTED;
}

heap_alloc :: proc(size: int) -> rawptr {
	return nil;
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return nil;
}

heap_free :: proc(ptr: rawptr) {
}

current_thread_id :: proc "contextless" () -> int {
	// return int(EsThreadGetID(ES_CURRENT_THREAD));
	return -1;
}

OS :: "essence";
