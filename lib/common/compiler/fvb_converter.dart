import 'code_processor.dart';

abstract class FVBConverter<T> {
  T toDart(FVBInstance instance);
  void fromDart(String name, List<dynamic> instances);
  dynamic convert(dynamic value) {
    if (value is FVBInstance) {
      return value;
    }
    return value;
  }
}
