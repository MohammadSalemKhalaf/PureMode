// Conditional export: dart:io on mobile/desktop, stub on web.
export 'io_stub.dart' if (dart.library.io) 'dart:io';
