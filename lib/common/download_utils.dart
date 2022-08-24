import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_builder/common/html_lib.dart' as html;
import 'package:permission_handler/permission_handler.dart';

class DownloadUtils {
  static void download(Map<String, dynamic> data, String fileName) async {
    // Encode our file in base64
    final encoder = ZipEncoder();
    final archive = Archive();
    for (final entry in data.entries) {
      if (entry.key.endsWith('.jpg') || entry.key.endsWith('.jpeg') || entry.key.endsWith('.png')) {
        archive.addFile(
          ArchiveFile.stream(entry.key, (entry.value as Uint8List).length, InputStream(entry.value as Uint8List)),
        );
      } else {
        archive.addFile(ArchiveFile.string(entry.key, entry.value));
      }
    }
    final outputStream = OutputStream(
      byteOrder: LITTLE_ENDIAN,
    );
    final bytes = encoder.encode(archive, level: Deflate.BEST_COMPRESSION, output: outputStream);

    if (kIsWeb) {
      final _base64 = base64Encode(bytes!);
      // Create the link with the file
      final anchor = html.getAnchorElement(href: 'data:application/octet-stream;base64,$_base64')..target = 'blank';
      // add the name
      anchor.download = fileName + '.zip';
      // trigger download
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } else {
      if (!await Permission.storage.isGranted) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return;
        }
      }
      FileSaver.instance
          .saveFile(fileName, Uint8List.fromList(bytes!), 'zip', mimeType: MimeType.ZIP)
          .then((value) {})
          .onError((error, stackTrace) {});
    }
    return;
  }
}
