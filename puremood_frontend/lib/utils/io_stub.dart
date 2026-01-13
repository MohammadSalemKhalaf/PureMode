// Web stub for dart:io types used in the app.
// Only implements the minimal surface needed for compilation.

class File {
  final String path;
  File(this.path);

  Future<List<int>> readAsBytes() {
    throw UnsupportedError('File is not supported on web.');
  }

  Future<bool> exists() async {
    return false;
  }

  Stream<List<int>> openRead() {
    throw UnsupportedError('File is not supported on web.');
  }

  Future<int> length() async {
    throw UnsupportedError('File is not supported on web.');
  }

  Future<File> writeAsBytes(List<int> bytes) {
    throw UnsupportedError('File is not supported on web.');
  }

  Future<File> copy(String newPath) {
    throw UnsupportedError('File is not supported on web.');
  }

  Future<void> delete() async {
    throw UnsupportedError('File is not supported on web.');
  }
}

class Directory {
  final String path;
  Directory(this.path);

  Future<bool> exists() async {
    return false;
  }

  Future<Directory> create({bool recursive = false}) {
    throw UnsupportedError('Directory is not supported on web.');
  }

  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) {
    return const Stream.empty();
  }

  Future<void> delete({bool recursive = false}) async {
    throw UnsupportedError('Directory is not supported on web.');
  }
}

class FileSystemEntity {}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static String get operatingSystemVersion => 'web';
  static String get pathSeparator => '/';
}
