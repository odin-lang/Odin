package archive_sevenz

// Opens a 7z archive from a byte slice or a stream
open :: proc{open_from_bytes, open_from_stream}

// Starts a new 7z archive on a stream
create :: proc{create_from_stream}

// Opens a 7z archive on a stream for changes
update :: proc{update_from_stream}
