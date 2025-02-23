import 'package:flutter_builder/cubit/screen_config/screen_config_cubit.dart';

import 'code_processor.dart';
import 'fvb_class.dart';
import 'fvb_function_variables.dart';

void dummyTest() {}

class FVBDartOperations {
  static final intOperations = FVBClass.create('int', vars: {
    'bitLength': () => FVBVariable(
          'bitLength',
          DataType.fvbInt,
          getCall: (object, processor) => (object as int).bitLength,
        ),
    'sp': () => FVBVariable(
          'sp',
          DataType.fvbDouble,
          getCall: (object, processor) =>
              (object as int) * selectedConfig!.width,
        ),
    'w': () => FVBVariable(
          'w',
          DataType.fvbDouble,
          getCall: (object, processor) =>
              (object as int) * selectedConfig!.width,
        ),
    'h': () => FVBVariable(
          'h',
          DataType.fvbDouble,
          getCall: (object, processor) =>
              (object as int) * selectedConfig!.height,
        ),
  }, funs: [
    FVBFunction('toStringAsFixed', null, [
      FVBArgument('fractionDigits', dataType: DataType.fvbInt)
    ], dartCall: (args, instance) {
      return (args[0] as int).toStringAsFixed(args[1]);
    }, returnType: DataType.string),
    FVBFunction('toString', null, [], dartCall: (args, instance) {
      return (args[0] as int).toString();
    }, returnType: DataType.string),
  ], staticFuns: [
    FVBFunction('parse', null, [FVBArgument('text')])
      ..dartCall = (arguments, instance) => arguments[0] is FVBTest ||
              Processor.operationType == OperationType.checkOnly
          ? const FVBTest(DataType.fvbInt, false)
          : int.parse(arguments[0]),
    FVBFunction('tryParse', null, [FVBArgument('text')], canReturnNull: true)
      ..dartCall = (arguments, instance) => arguments[0] is FVBTest ||
              Processor.operationType == OperationType.checkOnly
          ? const FVBTest(DataType.fvbInt, true)
          : int.tryParse(arguments[0])
  ]);
  static final doubleOperations = FVBClass.create(
    'double',
    staticVars: [
      FVBVariable('infinity', DataType.fvbDouble, value: double.infinity)
    ],
    vars: {
      'sp': () => FVBVariable(
            'sp',
            DataType.fvbInt,
            getCall: (object, processor) =>
                (object as double) * selectedConfig!.width,
          ),
      'w': () => FVBVariable(
            'w',
            DataType.fvbInt,
            getCall: (object, processor) =>
                (object as double) * selectedConfig!.width,
          ),
      'h': () => FVBVariable(
            'h',
            DataType.fvbInt,
            getCall: (object, processor) =>
                (object as double) * selectedConfig!.height,
          ),
    },
    funs: [
      FVBFunction('toStringAsFixed', null, [
        FVBArgument('fractionDigits', dataType: DataType.fvbDouble)
      ], dartCall: (args, instance) {
        return (args[0] as double).toStringAsFixed(args[1]);
      }, returnType: DataType.string),
      FVBFunction('toString', null, [], dartCall: (args, instance) {
        return (args[0] as double).toString();
      }, returnType: DataType.string),
    ],
    staticFuns: [
      FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments, instance) => arguments[0] is FVBTest
            ? const FVBTest(DataType.fvbDouble, false)
            : double.parse(arguments[0]),
      FVBFunction('tryParse', null, [FVBArgument('text')], canReturnNull: true)
        ..dartCall = (arguments, instance) => arguments[0] is FVBTest
            ? const FVBTest(DataType.fvbDouble, true)
            : double.tryParse(arguments[0])
    ],
  );
  static final numOperations = FVBClass.create(
    'num',
    vars: {
      'sp': () => FVBVariable(
            'sp',
            DataType.fvbNum,
            getCall: (object, processor) =>
                (object as num) * selectedConfig!.width,
          ),
      'w': () => FVBVariable(
            'w',
            DataType.fvbNum,
            getCall: (object, processor) =>
                (object as num) * selectedConfig!.width,
          ),
      'h': () => FVBVariable(
            'h',
            DataType.fvbNum,
            getCall: (object, processor) =>
                (object as num) * selectedConfig!.height,
          ),
    },
    funs: [
      FVBFunction('toString', null, [], dartCall: (args, instance) {
        return (args[0] as num).toString();
      }, returnType: DataType.string),
    ],
    staticFuns: [
      FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments, instance) => arguments[0] is FVBTest
            ? const FVBTest(DataType.fvbNum, false)
            : num.parse(arguments[0]),
      FVBFunction('tryParse', null, [FVBArgument('text')], canReturnNull: true)
        ..dartCall = (arguments, instance) => arguments[0] is FVBTest
            ? const FVBTest(DataType.fvbNum, true)
            : num.tryParse(arguments[0])
    ],
  );
  static final toListFunction = FVBFunction(
      'toList',
      null,
      [
        FVBArgument(
          'growable',
          type: FVBArgumentType.optionalNamed,
          defaultVal: true,
        )
      ],
      returnType: DataType.list(DataType.fvbDynamic),
      dartCall: (args, instance) {
    return (args[0] as Iterable).toList(growable: args[1] as bool);
  });

  static final joinFunction = FVBFunction('join', null, [
    FVBArgument(
      'separator',
      type: FVBArgumentType.optionalPlaced,
      dataType: DataType.string,
      defaultVal: '',
    ),
  ], dartCall: (args, instance) {
    if (Processor.operationType == OperationType.checkOnly) {
      return '';
    }

    return (args[0] as Iterable).join(args[1] as String);
  }, returnType: DataType.string);
  static final stringOperations = FVBClass.create('String', vars: {
    'length': () => FVBVariable(
          'length',
          DataType.fvbInt,
          getCall: (object, processor) => (object as String).length,
        ),
    'isEmpty': () => FVBVariable(
          'isEmpty',
          DataType.fvbBool,
          getCall: (object, processor) => (object as String).isEmpty,
        ),
    'isNotEmpty': () => FVBVariable(
          'isNotEmpty',
          DataType.fvbBool,
          getCall: (object, processor) => (object as String).isNotEmpty,
        ),
  }, funs: [
    FVBFunction(
      'substring',
      null,
      [
        FVBArgument('start',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
        FVBArgument('end',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            nullable: true)
      ],
      dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return const FVBTest(DataType.string, false);
        }
        return (args[0] as String).substring(args[1] as int, args[2] as int?);
      },
      returnType: DataType.string,
    ),
    FVBFunction(
      'toUpperCase',
      null,
      [],
      dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return const FVBTest(DataType.string, false);
        }
        return (args[0] as String).toUpperCase();
      },
      returnType: DataType.string,
    ),
    FVBFunction(
      'toLowerCase',
      null,
      [],
      dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return const FVBTest(DataType.string, false);
        }
        return (args[0] as String).toLowerCase();
      },
      returnType: DataType.string,
    ),
    FVBFunction(
      'indexOf',
      null,
      [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('start',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            defaultVal: 0),
      ],
      dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return const FVBTest(DataType.fvbInt, false);
        }
        return (args[0] as String).indexOf(args[1] as String, args[2] as int);
      },
      returnType: DataType.fvbInt,
    ),
    FVBFunction('lastIndexOf', null, [
      FVBArgument('search',
          type: FVBArgumentType.placed, dataType: DataType.string),
      FVBArgument('start',
          type: FVBArgumentType.optionalPlaced,
          dataType: DataType.fvbInt,
          defaultVal: 0),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.fvbInt, false);
      }
      return (args[0] as String).lastIndexOf(args[1] as String, args[2] as int);
    }, returnType: DataType.fvbInt),
    FVBFunction('replace', null, [
      FVBArgument('search',
          type: FVBArgumentType.placed, dataType: DataType.string),
      FVBArgument('replace',
          type: FVBArgumentType.placed, dataType: DataType.string),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.string, false);
      }
      return (args[0] as String)
          .replaceAll(args[1] as String, args[2] as String);
    }, returnType: DataType.string),
    FVBFunction(
      'split',
      null,
      [
        FVBArgument('separator',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.string,
            defaultVal: ''),
      ],
      returnType: DataType.iterable(DataType.string),
      dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return FVBTest(DataType.list(DataType.string), false);
        }
        return (args[0] as String).split(args[1] as String);
      },
    ),
    FVBFunction('trim', null, [], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.string, false);
      }
      return (args[0] as String).trim();
    }, returnType: DataType.string),
    FVBFunction('trimLeft', null, [], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.string, false);
      }
      return (args[0] as String).trimLeft();
    }, returnType: DataType.string),
    FVBFunction('trimRight', null, [], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.string, false);
      }
      return (args[0] as String).trimRight();
    }, returnType: DataType.string),
    //replaceAll
    FVBFunction('replaceAll', null, [
      FVBArgument('search',
          type: FVBArgumentType.placed, dataType: DataType.string),
      FVBArgument('replace',
          type: FVBArgumentType.placed, dataType: DataType.string),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.string, false);
      }
      return (args[0] as String)
          .replaceAll(args[1] as String, args[2] as String);
    }, returnType: DataType.string),
    //replaceFirst
    FVBFunction('replaceFirst', null, [
      FVBArgument('search',
          type: FVBArgumentType.placed, dataType: DataType.string),
      FVBArgument('replace',
          type: FVBArgumentType.placed, dataType: DataType.string),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.string, false);
      }
      return (args[0] as String)
          .replaceFirst(args[1] as String, args[2] as String);
    }, returnType: DataType.string),
    //contains
    FVBFunction('contains', null, [
      FVBArgument('search',
          type: FVBArgumentType.placed, dataType: DataType.string),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.fvbBool, false);
      }
      return (args[0] as String).contains(args[1] as String);
    }, returnType: DataType.fvbBool),
    //startsWith
    FVBFunction('startsWith', null, [
      FVBArgument('search',
          type: FVBArgumentType.placed, dataType: DataType.string),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.fvbBool, false);
      }
      return (args[0] as String).startsWith(args[1] as String);
    }, returnType: DataType.fvbBool),
    //endsWith
    FVBFunction('endsWith', null, [
      FVBArgument('search',
          type: FVBArgumentType.placed, dataType: DataType.string),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.fvbBool, false);
      }
      return (args[0] as String).endsWith(args[1] as String);
    }, returnType: DataType.fvbBool),
    //replaceRange
    FVBFunction('replaceRange', null, [
      FVBArgument('start',
          type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      FVBArgument('end',
          type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      FVBArgument('replace',
          type: FVBArgumentType.placed, dataType: DataType.string),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.string, false);
      }
      return (args[0] as String)
          .replaceRange(args[1] as int, args[2] as int, args[3] as String);
    }, returnType: DataType.string),
  ]);
  static final iterableOperation = FVBClass.create('Iterable', vars: {
    'length': () => FVBVariable(
          'length',
          DataType.fvbInt,
          getCall: (object, processor) => (object as Iterable).length,
        ),
  }, funs: [
    FVBFunction(
        'map',
        null,
        [
          FVBArgument('callback',
              type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
        ],
        returnType: DataType.iterable(null), dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return FVBTest(DataType.iterable(instance?.generics['T']), false);
      }
      return (args[0] as Iterable).map((e) {
        return (args[1] as FVBFunction)
            .execute(args.last as Processor, instance, [e]);
      }).toList();
    }),
    FVBFunction('contains', null, [
      FVBArgument('element',
          type: FVBArgumentType.placed, dataType: DataType.fvbDynamic),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.fvbBool, false);
      }
      return (args[0] as Iterable).contains(args[1] as dynamic);
    }, returnType: DataType.fvbBool),
    //aslist
    toListFunction,
    joinFunction
  ], generics: [
    'T'
  ]);
  static final mapEntryOperation = FVBClass.create('MapEntry', vars: {
    'key': () => FVBVariable('key', DataType.generic('K'),
        getCall: (object, processor) =>
            Processor.operationType == OperationType.checkOnly
                ? FVBTest(DataType.generic('K'), false)
                : (object as MapEntry).key),
    'value': () => FVBVariable('value', DataType.generic('V'),
        getCall: (object, processor) =>
            Processor.operationType == OperationType.checkOnly
                ? FVBTest(DataType.generic('V'), false)
                : (object as MapEntry).value),
  }, generics: [
    'K',
    'V'
  ]);
  static final mapOperation = FVBClass.create('Map', vars: {
    'length': () => FVBVariable(
          'length',
          DataType.fvbInt,
          getCall: (object, processor) =>
              Processor.operationType == OperationType.checkOnly
                  ? const FVBTest(DataType.fvbInt, false)
                  : (object as Map).length,
        ),
    'entries': () => FVBVariable(
          'entries',
          DataType.list(DataType.fvbInstance('MapEntry')),
          getCall: (object, processor) =>
              Processor.operationType == OperationType.checkOnly
                  ? FVBTest(DataType.iterable(), false)
                  : (object as Map).entries,
        ),
    'keys': () => FVBVariable(
          'keys',
          DataType.list(DataType.generic('K')),
          getCall: (object, processor) =>
              Processor.operationType == OperationType.checkOnly
                  ? FVBTest(DataType.iterable(), false)
                  : (object as Map).keys,
        ),
    'values': () => FVBVariable(
          'values',
          DataType.list(DataType.generic('V')),
          getCall: (object, processor) =>
              Processor.operationType == OperationType.checkOnly
                  ? FVBTest(DataType.iterable(), false)
                  : (object as Map).values,
        ),
  }, funs: [
    FVBFunction('addAll', null, [
      FVBArgument('map',
          type: FVBArgumentType.placed, dataType: DataType.map()),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      (args[0] as Map).addAll(args[1] as Map);
    }),

    /// TODO(AddMapEntry):
    FVBFunction('remove', null, [
      FVBArgument('key',
          type: FVBArgumentType.placed, dataType: DataType.fvbDynamic),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.fvbDynamic, true);
      }
      return (args[0] as Map).remove(args[1] as dynamic);
    }),
    FVBFunction('containsKey', null, [
      FVBArgument('key',
          type: FVBArgumentType.placed, dataType: DataType.fvbDynamic),
    ], dartCall: (args, instance) {
      return (args[0] as Map).containsKey(args[1] as dynamic);
    }, returnType: DataType.fvbBool),
    FVBFunction('containsValue', null, [
      FVBArgument('value',
          type: FVBArgumentType.placed, dataType: DataType.fvbDynamic),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return const FVBTest(DataType.fvbBool, false);
      }
      return (args[0] as Map).containsValue(args[1] as dynamic);
    }, returnType: DataType.fvbBool),
    FVBFunction('clear', null, [], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      (args[0] as Map).clear();
    }),
    FVBFunction('forEach', null, [
      FVBArgument('callback',
          type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        (args[1] as FVBFunction).execute(args.last as Processor, instance,
            [FVBTest.kDynamic, FVBTest.kDynamic]);
        return const FVBTest(DataType.fvbVoid, false);
      }
      (args[0] as Map).forEach((k, v) {
        (args[1] as FVBFunction)
            .execute(args.last as Processor, instance, [k, v]);
      });
    })
  ]);
  static final listOperation = FVBClass.create('List', generics: [
    'T'
  ], staticFuns: [
    FVBFunction(
        'filled',
        null,
        [
          FVBArgument('length', dataType: DataType.fvbInt),
          FVBArgument(
            'fill',
            dataType: DataType.fvbDynamic,
          ),
          FVBArgument(
            'growable',
            dataType: DataType.fvbBool,
            defaultVal: false,
            type: FVBArgumentType.optionalPlaced,
          ),
        ],
        dartCall: (args, instance) =>
            List.filled(args[0], args[1], growable: args[2]))
  ], vars: {
    'length': () => FVBVariable(
          'length',
          DataType.fvbInt,
          getCall: (object, processor) => (object as List).length,
        ),
  }, funs: [
    toListFunction,
    FVBFunction('add', null, [
      FVBArgument('element',
          type: FVBArgumentType.placed, dataType: DataType.generic('T')),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      if (args[0] is List) {
        (args[0] as List).add(args[1] as dynamic);
      }
      return args[1];
    }),
    FVBFunction('remove', null, [
      FVBArgument('index',
          type: FVBArgumentType.placed, dataType: DataType.fvbInt),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      (args[0] as List).removeAt(args[1] as int);
      return args[1];
    }),
    FVBFunction('insert', null, [
      FVBArgument('index',
          type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      FVBArgument('element',
          type: FVBArgumentType.placed, dataType: DataType.fvbDynamic),
    ], dartCall: (args, instance) {
      (args[0] as List).insert(args[1] as int, args[2] as dynamic);
      return args[1];
    }),
    FVBFunction('removeAt', null, [
      FVBArgument('index',
          type: FVBArgumentType.placed, dataType: DataType.fvbInt),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      (args[0] as List).removeAt(args[1] as int);
      return args[1];
    }),
    FVBFunction('removeRange', null, [
      FVBArgument('start',
          type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      FVBArgument(
        'end',
        type: FVBArgumentType.placed,
        dataType: DataType.fvbInt,
      ),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      (args[0] as List).removeRange(args[1] as int, args[2] as int);
      return args[1];
    }),
    FVBFunction('clear', null, [], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      (args[0] as List).clear();
      return null;
    }),
    FVBFunction(
        'map',
        null,
        [
          FVBArgument('callback',
              type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
        ],
        returnType: DataType.iterable(null), dartCall: (args, instance) {
      return (args[0] as List).map((e) {
        return (args[1] as FVBFunction)
            .execute(args.last as Processor, instance, [e]);
      }).toList();
    }),
    FVBFunction('contains', null, [
      FVBArgument('element',
          type: FVBArgumentType.placed, dataType: DataType.fvbDynamic),
    ], dartCall: (args, instance) {
      return (args[0] as List).contains(args[1] as dynamic);
    }),
    FVBFunction('indexOf', null, [
      FVBArgument('element',
          type: FVBArgumentType.placed, dataType: DataType.fvbDynamic),
      FVBArgument('start',
          type: FVBArgumentType.optionalPlaced,
          dataType: DataType.fvbInt,
          defaultVal: 0),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return -1;
      }
      return (args[0] as List).indexOf(args[1] as dynamic, args[2] as int);
    }),
    //asMap
    FVBFunction('asMap', null, [], returnType: DataType.map(null),
        dartCall: (args, instance) {
      return (args[0] as List).asMap();
    }),
    //for each
    FVBFunction('forEach', null, [
      FVBArgument('callback',
          type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
    ], dartCall: (args, instance) {
      for (final e in (args[0] as List)) {
        (args[1] as FVBFunction).execute(args.last as Processor, instance, [e]);
      }
      return null;
    }),
    //where
    FVBFunction(
        'where',
        null,
        [
          FVBArgument('callback',
              type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
        ],
        returnType: DataType.iterable(null), dartCall: (args, instance) {
      return (args[0] as List).where((e) {
        return (args[1] as FVBFunction)
            .execute(args.last as Processor, instance, [e]);
      }).toList();
    }),
    //remove where
    FVBFunction('removeWhere', null, [
      FVBArgument('callback',
          type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      (args[0] as List).removeWhere((e) {
        return (args[1] as FVBFunction)
            .execute(args.last as Processor, instance, [e]);
      });
      return null;
    }),
    //add all
    FVBFunction('addAll', null, [
      FVBArgument('elements',
          type: FVBArgumentType.placed, dataType: DataType.iterable(null)),
    ], dartCall: (args, instance) {
      if (Processor.operationType == OperationType.checkOnly) {
        return;
      }
      for (final v in args[1]) {
        (args[0] as List<dynamic>).add(v);
      }
      return null;
    }),
    joinFunction,
  ]);
}
