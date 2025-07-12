import 'package:flutter_builder/ai/json_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late JSONCleaner jsonCleaner;
  setUp(() {
    jsonCleaner = JSONCleaner();
  });

  test('Test auto fix curly bracket', () {
    expect(jsonCleaner.fixMalformedJson('''{
  "name":"tester"
  }}'''), '''{
  "name":"tester"
  }''');

    expect(jsonCleaner.fixMalformedJson('''{
  "name":"tester",
  "list":[
  {
  "test":"test"
  }}
  ]
  }'''), '''{
  "name":"tester",
  "list":[
  {
  "test":"test"
  }
  ]
  }''');
  });
}
