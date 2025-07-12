class IOOperations {
  static void createJsonFile(String dir, String filename, Map<String, dynamic> data) async {
    print("ON WEB: Can't create File");
  }

  static Future<Map<String, dynamic>> readJsonFile(String dir, String filename) async {
    return {};
  }

  static Future<String> runJsonRepair(String brokenJson) async {
    return brokenJson;
  }
}
