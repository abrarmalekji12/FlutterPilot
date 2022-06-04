import 'dart:convert';
import 'dart:html';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class DownloadUtils {
  static void download(Map<String, dynamic> data, String fileName) {
    // Encode our file in base64
    final encoder = ZipEncoder();
    final archive = Archive();
    for (final entry in data.entries) {
      if (entry.key.endsWith('.jpg') ||
          entry.key.endsWith('.jpeg') ||
          entry.key.endsWith('.png')) {
        archive.addFile(
          ArchiveFile.stream(entry.key, (entry.value as Uint8List).length,
              InputStream(entry.value as Uint8List)),
        );
      } else {
        archive.addFile(ArchiveFile.string(entry.key, entry.value));
      }
    }
    final outputStream = OutputStream(
      byteOrder: LITTLE_ENDIAN,
    );
    final bytes = encoder.encode(archive,
        level: Deflate.BEST_COMPRESSION, output: outputStream);

    final _base64 = base64Encode(bytes!);
    // Create the link with the file
    final anchor =
        AnchorElement(href: 'data:application/octet-stream;base64,$_base64')
          ..target = 'blank';
    // add the name
    anchor.download = fileName + '.zip';
    // trigger download
    document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return;
  }
}
