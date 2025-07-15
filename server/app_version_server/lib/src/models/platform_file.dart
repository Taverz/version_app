import 'dart:typed_data';

import 'package:meta/meta.dart';

@immutable
class PlatformFile {
  final String name;
  final int size;
  final Uint8List? bytes;

  const PlatformFile({required this.name, required this.size, this.bytes});
}
