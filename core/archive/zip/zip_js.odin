package archive_zip

// Opens a zip archive from a byte slice or a stream
open :: proc{open_from_bytes, open_from_stream}

// Starts a new zip archive on a stream
create :: proc{create_from_stream}

// Opens a zip archive on a stream for changes
update :: proc{update_from_stream}
