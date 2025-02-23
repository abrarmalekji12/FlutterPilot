import 'code_processor.dart';

abstract class Arguments {
  static final buildContext =
      FVBArgument('context', dataType: DataType.fvbDynamic);
}
