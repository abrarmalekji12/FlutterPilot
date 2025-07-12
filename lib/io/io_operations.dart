import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class IOOperations {
  static void createJsonFile(String dir, String filename, Map<String, dynamic> data) async {
    // Convert to JSON string
    String jsonString = jsonEncode(data);

    // Get user document directory
    final currentDir = Directory.current;

    // Create subdirectory 'prompts' if it doesn't exist
    final promptsDir = Directory('${currentDir.path}/$dir');
    if (!await promptsDir.exists()) {
      await promptsDir.create(recursive: true);
    }

    // File path: prompts/file.json
    final file = File('${promptsDir.path}/$filename');

    // Write to file
    await file.writeAsString(jsonString, mode: FileMode.write);

    print('✅ $filename File created at: ${file.path}');
  }

  static Future<Map<String, dynamic>> readJsonFile(String dir, String filename) async {
    try {
      final currentDir = Directory.current;
      final file = File('${currentDir.path}/$dir/$filename');

      if (await file.exists()) {
        String contents = await file.readAsString();
        return jsonDecode(contents);
      } else {
        print('❌ File not found: ${file.path}');
        return {};
      }
    } catch (e) {
      print('❌ Error reading file: $e');
      return {};
    }
  }

  static Future<String> runJsonRepair(String brokenJson) async {
    final process = await Process.start('node', ['/Users/abrarmalekji/StudioProjects/flutter_builder/js/json_repair.js']);

    // Send the broken JSON
    process.stdin.writeln(brokenJson);
    await process.stdin.flush();
    await process.stdin.close();

    // Read the output
    final output = await process.stdout.transform(utf8.decoder).join();
    final error = await process.stderr.transform(utf8.decoder).join();

    if (error.isNotEmpty) {
      throw Exception('JSON Repair Error: $error');
    }

    return output.trim();
  }

  static Future<List<String>> fetchMaterialIcons() async {
    List<String> icons = [];
    Icons.add;
    final iconFile = File('/Users/abrarmalekji/Documents/flutter/packages/flutter/lib/src/material/icons.dart');
    String contents = await iconFile.readAsString();
    const starting = '  static const IconData ';
    for (final line in contents.split('\n')) {
      if (line.startsWith(starting)) {
        final name = line.substring(starting.length, line.indexOf('=', starting.length)).trim();
        icons.add('\'${name}\':Icons.$name');
      }
    }

    return icons;
  }
}
