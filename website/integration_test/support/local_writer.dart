// Best-effort local JSON writer, chosen per platform so the frame benchmark
// compiles for web (no dart:io). Native writes files; web is a no-op.
library;

export 'local_writer_stub.dart'
    if (dart.library.io) 'local_writer_io.dart';
