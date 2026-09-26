import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A file chosen by the user, always carrying its bytes.
///
/// Bytes are used on every platform so that uploads work identically on web
/// (where there is no filesystem path) and on mobile/desktop.
class PickedFileData {
  const PickedFileData({required this.name, required this.bytes, this.path});

  final String name;
  final Uint8List bytes;
  final String? path;

  int get size => bytes.length;
}

/// Thrown when a file was selected but its content could not be read.
class FilePickException implements Exception {
  const FilePickException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Picks an image (avatar, thumbnail, banner, ...).
Future<PickedFileData?> pickImageFile() => _pick(FileType.image);

/// Picks a video file for upload.
Future<PickedFileData?> pickVideoFile() => _pick(FileType.video);

/// Picks any file matching [extensions] (e.g. `['torrent']`).
Future<PickedFileData?> pickAnyFile({List<String>? extensions}) =>
    _pick(FileType.custom, allowedExtensions: extensions);

Future<PickedFileData?> _pick(FileType type, {List<String>? allowedExtensions}) async {
  final result = await FilePicker.platform.pickFiles(
    type: type,
    allowedExtensions: allowedExtensions,
    withData: true,
  );

  final file = result?.files.single;
  if (file == null) return null;

  final bytes = file.bytes;
  if (bytes == null) {
    throw const FilePickException('无法读取所选文件的内容，请换一个文件试试。');
  }

  return PickedFileData(name: file.name, bytes: bytes, path: file.path);
}
