package archive_tar

// Opens a tar archive from a byte slice or a stream
open :: proc{open_from_bytes, open_from_stream}

// Starts a new tar archive on a stream
create :: proc{create_from_stream}
