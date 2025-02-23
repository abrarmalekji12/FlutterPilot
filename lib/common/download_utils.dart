import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dart_style/dart_style.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'web/io_lib.dart';
import 'package:permission_handler/permission_handler.dart';

import 'web/html_lib.dart' as html;

class DownloadUtils {
  static Future<String?> downloadWithoutZip(
      Map<String, dynamic> data, String fileName) async {
    if (kIsWeb) {
      download(data, fileName);
      return null;
    }
    final instance = FileSaver.instance;
    if ((Platform.isAndroid || Platform.isIOS) &&
        !await Permission.storage.isGranted) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return null;
      }
    }
    final DartFormatter formatter = DartFormatter();
    final downloadDir = await getDownloadsDirectory();

    final dir = Directory('${downloadDir!.path}/${fileName}/lib');
    await dir.delete(recursive: true);

    for (final entry in data.entries) {
      final i = entry.key.lastIndexOf('.');
      final name = i >= 0 ? entry.key.substring(0, i) : entry.key;
      final ext = i >= 0 ? entry.key.substring(i + 1) : '';
      final path = fileName + '/' + name;
      final lastSlash = path.lastIndexOf('/');
      if (path.isNotEmpty) {
        final dir =
            Directory('${downloadDir.path}/${path.substring(0, lastSlash)}');
        await dir.create(recursive: true);
      }
      if (['jpg', 'jpeg', 'png'].contains(ext)) {
        await instance.saveFile(
            name: path, bytes: entry.value as Uint8List, ext: ext);
      } else {
        String code = '';
        if (ext == 'dart' && code.isNotEmpty) {
          code = formatter.format(entry.value as String);
        } else {
          code = entry.value as String;
        }
        await instance.saveFile(
            name: path, bytes: Uint8List.fromList(utf8.encode(code)), ext: ext);
      }
    }
    return '${downloadDir.path}/$fileName';
  }

  static void download(Map<String, dynamic> data, String fileName) async {
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

    if (kIsWeb) {
      final _base64 = base64Encode(bytes!);
// Create the link with the file
      final anchor = html.getAnchorElement(
          href: 'data:application/octet-stream;base64,$_base64')
        ..target = 'blank';
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
          .saveAs(
            name: fileName,
            bytes: Uint8List.fromList(bytes!),
            ext: 'zip',
            mimeType: MimeType.zip,
          )
          .then((value) {})
          .onError((error, stackTrace) {});
    }
    return;
  }
}
