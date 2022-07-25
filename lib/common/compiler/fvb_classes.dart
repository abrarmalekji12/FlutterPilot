import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/variable_model.dart';
import 'code_processor.dart';
import 'fvb_converter.dart';

class FVBModuleClasses {
  static Map<String, FVBClass> fvbClasses = {
    'Size': FVBClass.create('Size', vars: {
      'width': () => FVBVariable('width', DataType.fvbDouble),
      'height': () => FVBVariable('height', DataType.fvbDouble),
    },funs: [
      FVBFunction('Size', '', [
        FVBArgument('this.width', dataType:DataType.fvbDouble),
        FVBArgument('this.height', dataType:DataType.fvbDouble),
      ])
    ]),
    'Rect': FVBClass.create('Rect',
        vars: {
          'left': () => FVBVariable('left', DataType.fvbDouble),
          'top': () => FVBVariable('top', DataType.fvbDouble),
          'right': () => FVBVariable('right', DataType.fvbDouble),
          'bottom': () => FVBVariable('bottom', DataType.fvbDouble),
        },
        funs: [
          FVBFunction(
            'Rect.fromLTRB',
            '',
            [
              FVBArgument('this.left', dataType: DataType.fvbDouble),
              FVBArgument('this.top', dataType: DataType.fvbDouble),
              FVBArgument('this.right', dataType: DataType.fvbDouble),
              FVBArgument('this.bottom', dataType: DataType.fvbDouble),
            ],
          ),
          FVBFunction('Rect.fromPoints', null, [
            FVBArgument('a'),
            FVBArgument('b'),
          ]),
        ],
        converter: RectConverter()),
    'Offset': FVBClass.create('Offset',
        funs: [
          FVBFunction(
            'Offset',
            null,
            [
              FVBArgument('this.dx', dataType: DataType.fvbDouble),
              FVBArgument('this.dy', dataType: DataType.fvbDouble)
            ],
          ),
        ],
        vars: {
          'dx': () => FVBVariable('dx', DataType.fvbDouble),
          'dy': () => FVBVariable('dy', DataType.fvbDouble),
        },
        converter: OffsetConverter()),
    'TextField': FVBClass('TextField', {
      'setText': FVBFunction('setText', null, [FVBArgument('text')]),
      'clear': FVBFunction('clear', '', []),
    }, {
      'text': () => FVBVariable('text', DataType.string),
    }),
    'Future': FVBClass('Future', {
      'Future.delayed': FVBFunction('Future.delayed', '', [
        FVBArgument('duration', dataType: DataType.fvbInstance('Duration')),
        FVBArgument('computation',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbFunction,
            nullable: true)
      ], dartCall: (args) {
        final processor = args[2] as CodeProcessor;
        final fvbFuture = fvbClasses['Future']!.createInstance(processor, []);
        if (CodeProcessor.operationType == OperationType.checkOnly &&
            args.length > 1) {
          (args[1] as FVBFunction?)?.execute(processor, []);
        } else {
          fvbFuture.variables['future']!.value = Future.delayed(
              (args[0] as FVBInstance).toDart(),
              args[1] != null
                  ? () async {
                      if (CodeProcessor.error || processor.finished) {
                        return;
                      }
                      final result =
                          await (args[1] as FVBFunction).execute(processor, []);
                      (fvbFuture.variables['onValue']?.value as FVBFunction?)
                          ?.execute(processor, [result]);
                      return result;
                    }
                  : null);
        }
        return fvbFuture;
      }),
      'then': FVBFunction('then', 'onValue=value;',
          [FVBArgument('value', type: FVBArgumentType.optionalPlaced)]),
      'onError': FVBFunction('onError', 'onError=error;',
          [FVBArgument('error', type: FVBArgumentType.optionalPlaced)]),
    }, {
      'value': () => FVBVariable('value', DataType.dynamic),
      'future': () => FVBVariable('future', DataType.dynamic),
      'onValue': () =>
          FVBVariable('onValue', DataType.fvbFunction, nullable: true),
      'onError': () =>
          FVBVariable('onError', DataType.fvbFunction, nullable: true),
    }, generics: [
      'T'
    ]),
    'SharedPreferences': FVBClass.create('SharedPreferences', funs: [
      FVBFunction('SharedPreferences.getInstance', null, [],
          dartCall: (arguments) {
        final preferences = fvbClasses['SharedPreferences']!
            .createInstance(arguments[0] as CodeProcessor, []);

        final fvbFuture = fvbClasses['Future']!.createInstance(arguments[0], [],
            generics: [DataType.fvbInstance(preferences.fvbClass.name)]);
        fvbFuture.variables['future']!.value = Future<FVBInstance>(() async {
          final pref = await SharedPreferences.getInstance();
          preferences.variables['_pref']!.value = pref;
          fvbFuture.variables['value']!.value = preferences;
          (fvbFuture.variables['onValue']?.value as FVBFunction?)
              ?.execute(arguments[0] as CodeProcessor, [preferences]);
          return preferences;
        });

        return fvbFuture;
      }),
      FVBFunction('setInt', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbInt),
      ], dartCall: (arguments) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setInt(arguments[0] as String, arguments[1] as int);
        }
      }),
      FVBFunction('setString', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.string),
      ], dartCall: (arguments) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setString(arguments[0] as String, arguments[1] as String);
        }
      }),
      FVBFunction('setBool', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbBool),
      ], dartCall: (arguments) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setBool(arguments[0] as String, arguments[1] as bool);
        }
      }),
      FVBFunction('setDouble', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbDouble),
      ], dartCall: (arguments) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setDouble(arguments[0] as String, arguments[1] as double);
        }
      }),
      FVBFunction('setStringList', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.list([DataType.string])),
      ], dartCall: (arguments) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setStringList(
              arguments[0] as String, arguments[1] as List<String>);
        }
      }),
      FVBFunction('getInt', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getInt(arguments[0] as String);
        }
        return  FVBTest(DataType.fvbInt, false);
      }),
      FVBFunction('getString', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getString(arguments[0] as String);
        }
        return FVBTest(DataType.string, false);
      }),
      FVBFunction('getBool', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getBool(arguments[0] as String);
        }
        return FVBTest(DataType.fvbBool, false);
      }),
      FVBFunction('getDouble', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getDouble(arguments[0] as String);
        }
        return FVBTest(DataType.fvbDouble, false);
      }),
      FVBFunction('getStringList', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getStringList(arguments[0] as String);
        }
        return FVBTest(DataType.list([]), false);
      }),
      FVBFunction('containsKey', null, [
        FVBArgument('key', dataType: DataType.string),
      ], returnType:DataType.fvbBool,dartCall: (arguments) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref!.containsKey(arguments[0] as String);
        }
        return FVBTest(DataType.fvbBool, false);
      }),
      FVBFunction('clear', null, [
       ], isAsync: true,returnType:DataType.future,dartCall: (arguments) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref!.clear();
        }
        return FVBTest(DataType.fvbBool, false);
      }),

    ], vars: {
      '_pref': () => FVBVariable('_pref', DataType.dynamic)
    }),
    'Api': FVBClass('Api', {
      'get': FVBFunction('get', null, [FVBArgument('url')])
        ..dartCall = (arguments) async {
          return (await http.get(arguments[0])).body;
        },
    }, {}),
    'int': FVBClass('int', {}, {}, fvbStaticFunctions: {
      'parse': FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments) => arguments[0] is FVBTest?FVBTest(DataType.fvbInt, false):int.parse(arguments[0])
    }),
    'double': FVBClass('double', {}, {}, fvbStaticFunctions: {
      'parse': FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments) =>  arguments[0] is FVBTest?FVBTest(DataType.fvbInt, false):double.parse(arguments[0])
    }),
    'Duration': FVBClass(
        'Duration',
        {
          'Duration': FVBFunction('Duration', '', [
            FVBArgument('this.milliseconds',
                type: FVBArgumentType.optionalNamed, defaultVal: 0),
            FVBArgument('this.seconds',
                type: FVBArgumentType.optionalNamed, defaultVal: 0),
            FVBArgument('this.minutes',
                type: FVBArgumentType.optionalNamed, defaultVal: 0),
            FVBArgument('this.hours',
                type: FVBArgumentType.optionalNamed, defaultVal: 0),
            FVBArgument('this.days',
                type: FVBArgumentType.optionalNamed, defaultVal: 0),
          ]),
        },
        {
          'milliseconds': () => VariableModel('milliseconds', DataType.fvbInt),
          'seconds': () => VariableModel('seconds', DataType.fvbInt),
          'minutes': () => VariableModel('minutes', DataType.fvbInt),
          'hours': () => VariableModel('hours', DataType.fvbInt),
          'days': () => VariableModel('days', DataType.fvbInt),
        },
        converter: DurationConverter()),
    'Paint': FVBClass.create('Paint', vars: {
      'color': () => FVBVariable('color', DataType.fvbInstance('Color')),
      'strokeWidth': () => FVBVariable('strokeWidth', DataType.fvbDouble),
      'strokeCap': () => FVBVariable('strokeCap', DataType.string),
      'strokeJoin': () => FVBVariable('strokeJoin', DataType.string),
    },converter: PaintConverter()),
    'Color': FVBClass.create('Color',
        vars: {
          'value': () => FVBVariable('value', DataType.fvbInt),
        },
        funs: [
          FVBFunction('Color', '',
              [FVBArgument('this.value', type: FVBArgumentType.placed)])
        ],
        converter: ColorConverter()),
    'Colors':FVBClass.create('Colors',staticVars: [
      FVBVariable('black', DataType.fvbInstance('Color'),
          getCall: (obj)=>Colors.black),
      FVBVariable('red', DataType.fvbInstance('Color'),
          getCall: (obj) => Colors.red),
    ]),
    'Canvas': FVBClass.create('Canvas', funs: [
      FVBFunction('drawPoint', null, []),
      FVBFunction('drawRect', null, [
        FVBArgument('rect', dataType: DataType.fvbInstance('Rect')),
        FVBArgument('paint', dataType: DataType.fvbInstance('Paint')),
      ]),
    ]),
    'Timer': FVBClass(
        'Timer',
        {
          'Timer': FVBFunction(
              'Timer', '', [FVBArgument('duration'), FVBArgument('callback')]),
          'cancel': FVBFunction('cancel', '', []),
        },
        {},
        fvbStaticFunctions: {
          'periodic': FVBFunction('periodic', null,
              [FVBArgument('duration'), FVBArgument('callback')])
            ..dartCall = (arguments) {
              final timerInstance = fvbClasses['Timer']!
                  .createInstance(arguments[2], arguments.sublist(0, 2));

              if (CodeProcessor.operationType == OperationType.checkOnly) {
                (arguments[1] as FVBFunction)
                    .execute(arguments[2], [timerInstance]);
                timerInstance.fvbClass.fvbFunctions['cancel']!.dartCall =
                    (args) {};
              } else {
                final timer = Timer.periodic(
                    Duration(
                        milliseconds: (arguments[0] as FVBInstance)
                            .variables['milliseconds']!
                            .value), (timer) {
                  if ((arguments[2] as CodeProcessor).finished ||
                      CodeProcessor.error) {
                    timer.cancel();
                    return;
                  }
                  (arguments[1] as FVBFunction)
                      .execute(arguments[2], [timerInstance]);
                });
                CodeProcessor.timers.add(timer);
                timerInstance.fvbClass.fvbFunctions['cancel']!.dartCall =
                    (args) {
                  timer.cancel();
                  CodeProcessor.timers.remove(timer);
                };
              }

              return timerInstance;
            },
        },
        parent: null),
    'DateTime': FVBClass(
      'DateTime',
      {
        'DateTime': FVBFunction('DateTime', '', [
          FVBArgument(
            'this.year',
            type: FVBArgumentType.placed,
          ),
          FVBArgument('this.month',
              type: FVBArgumentType.optionalPlaced, defaultVal: 1),
          FVBArgument('this.day',
              type: FVBArgumentType.optionalPlaced, defaultVal: 1),
          FVBArgument('this.hour',
              type: FVBArgumentType.optionalPlaced, defaultVal: 0),
          FVBArgument('this.minute',
              type: FVBArgumentType.optionalPlaced, defaultVal: 0),
          FVBArgument('this.second',
              type: FVBArgumentType.optionalPlaced, defaultVal: 0),
          FVBArgument('this.millisecond',
              type: FVBArgumentType.optionalPlaced, defaultVal: 0),
        ]),
      },
      {
        'year': () => FVBVariable('year', DataType.fvbInt),
        'month': () => FVBVariable('month', DataType.fvbInt),
        'day': () => FVBVariable('day', DataType.fvbInt),
        'hour': () => FVBVariable('hour', DataType.fvbInt),
        'minute': () => FVBVariable('minute', DataType.fvbInt),
        'second': () => FVBVariable('second', DataType.fvbInt),
        'millisecond': () => FVBVariable('millisecond', DataType.fvbInt),
      },
      //     fvbStaticFunctions: {
      //   'now': FVBFunction('now', null, [])
      //     ..dartCall = (arguments) => fvbClasses['DateTime'].createInstance(processor, arguments),
      // }
    ),

    'String': FVBClass.create('String', vars: {
      'length': () => FVBVariable(
            'length',
            DataType.string,
            getCall: (object) => (object as String).length,
          ),
    }, funs: [
      FVBFunction('substring', null, [
        FVBArgument('start',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
        FVBArgument('end',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            nullable: true)
      ], dartCall: (args) {
        return (args[0] as String).substring(args[1] as int, args[2] as int?);
      }),
      FVBFunction('toUpperCase', null, [], dartCall: (args) {
        return (args[0] as String).toUpperCase();
      }),
      FVBFunction('toLowerCase', null, [], dartCall: (args) {
        return (args[0] as String).toLowerCase();
      }),
      FVBFunction('indexOf', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('start',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            defaultVal: 0),
      ], dartCall: (args) {
        return (args[0] as String).indexOf(args[1] as String, args[2] as int);
      }),
      FVBFunction('lastIndexOf', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('start',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            defaultVal: 0),
      ], dartCall: (args) {
        return (args[0] as String)
            .lastIndexOf(args[1] as String, args[2] as int);
      }),
      FVBFunction('replace', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('replace',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args) {
        return (args[0] as String)
            .replaceAll(args[1] as String, args[2] as String);
      }),
      FVBFunction('split', null, [
        FVBArgument('separator',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.string,
            defaultVal: ''),
      ],returnType: DataType.iterable(null), dartCall: (args) {
        return (args[0] as String).split(args[1] as String);
      }),
      FVBFunction('trim', null, [], dartCall: (args) {
        return (args[0] as String).trim();
      }),
      FVBFunction('trimLeft', null, [], dartCall: (args) {
        return (args[0] as String).trimLeft();
      }),
      FVBFunction('trimRight', null, [], dartCall: (args) {
        return (args[0] as String).trimRight();
      }),
      //replaceAll
      FVBFunction('replaceAll', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('replace',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args) {
        return (args[0] as String)
            .replaceAll(args[1] as String, args[2] as String);
      }),
    ]),
    'List': FVBClass.create('List', vars: {
      'length': () => FVBVariable(
            'length',
            DataType.fvbInt,
            getCall: (object) => (object as List).length,
          ),
    }, funs: [
      FVBFunction('add', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args) {
        if(args[0] is List) {
          (args[0] as List).add(args[1] as dynamic);
        }
        return args[1];
      }),
      FVBFunction('remove', null, [
        FVBArgument('index',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      ], dartCall: (args) {
        (args[0] as List).removeAt(args[1] as int);
        return args[1];
      }),
      FVBFunction('insert', null, [
        FVBArgument('index',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args) {
        (args[0] as List).insert(args[1] as int, args[2] as dynamic);
        return args[1];
      }),
      FVBFunction('removeAt', null, [
        FVBArgument('index',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      ], dartCall: (args) {
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
      ], dartCall: (args) {
        (args[0] as List).removeRange(args[1] as int, args[2] as int);
        return args[1];
      }),
      FVBFunction('clear', null, [], dartCall: (args) {
        (args[0] as List).clear();
        return null;
      }),
      FVBFunction('map', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
      ], returnType:DataType.iterable(null),dartCall: (args) {
        return (args[0] as List).map((e) {
          return (args[1] as FVBFunction).execute(args.last as CodeProcessor,[e]);
        }).toList();
      }),
      FVBFunction('contains', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args) {
        return (args[0] as List).contains(args[1] as dynamic);
      }),
      FVBFunction('indexOf', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
        FVBArgument('start',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            defaultVal: 0),
      ], dartCall: (args) {
        return (args[0] as List).indexOf(args[1] as dynamic, args[2] as int);
      }),
      //asMap
      FVBFunction('asMap', null, [], returnType: DataType.map(null), dartCall: (args) {
        return (args[0] as List).asMap();
      }),
      //for each
      FVBFunction('forEach', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
      ], dartCall: (args) {
        for (final e in (args[0] as List)) {
          (args[1] as FVBFunction).execute(args.last as CodeProcessor,[e]);
        }
        return null;
      }),
      //where
      FVBFunction('where', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
      ], returnType: DataType.iterable(null), dartCall: (args) {
        return (args[0] as List).where((e) {
          return (args[1] as FVBFunction).execute(args.last as CodeProcessor,[e]);
        }).toList();
      }),
      //remove where
      FVBFunction('removeWhere', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
      ], dartCall: (args) {
        (args[0] as List).removeWhere((e) {
          return (args[1] as FVBFunction).execute(args.last as CodeProcessor,[e]);
        });
        return null;
      }),
    ]),
    'Iterable': FVBClass.create('Iterable', vars: {
      'length': () => FVBVariable(
            'length',
            DataType.fvbInt,
            getCall: (object) => (object as Iterable).length,
          ),
    }, funs: [
      FVBFunction('map', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
      ], returnType:DataType.iterable(null), dartCall: (args) {
        return (args[0] as Iterable).map((e) {
          return (args[1] as FVBFunction).execute(args.last as CodeProcessor,[e]);
        }).toList();
      }),
      FVBFunction('contains', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args) {
        return (args[0] as Iterable).contains(args[1] as dynamic);
      }),
      //aslist
      FVBFunction('asList', null, [], returnType: DataType.list(null), dartCall: (args) {
        return (args[0] as Iterable).toList();
      }),
    ]),
    'Map': FVBClass.create('Map', vars: {
      'length': () => FVBVariable(
            'length',
            DataType.fvbInt,
            getCall: (object) => (object as Map).length,
          ),
    }, funs: [
      FVBFunction('addAll', null, [
        FVBArgument('map',
            type: FVBArgumentType.placed, dataType: DataType.map([])),
       ], dartCall: (args) {
        (args[0] as Map).addAll(args[1] as Map);
        return args[1];
      }),
      FVBFunction('remove', null, [
        FVBArgument('key',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args) {
        (args[0] as Map).remove(args[1] as dynamic);
        return args[1];
      }),
      FVBFunction('containsKey', null, [
        FVBArgument('key',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args) {
        return (args[0] as Map).containsKey(args[1] as dynamic);
      }),
      FVBFunction('containsValue', null, [
        FVBArgument('value',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args) {
        return (args[0] as Map).containsValue(args[1] as dynamic);
      }),
      FVBFunction('clear', null, [], dartCall: (args) {
        (args[0] as Map).clear();
      }),
      FVBFunction(
          'forEach',
          null,
          [
            FVBArgument('callback',
                type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
          ],
          dartCall: (args) {})
    ])
  };

  FVBModuleClasses() {
    // Rect offset = Rect.fromPoints(a, b);
  }

  static FVBInstance createFVBFuture(
      Future future, FVBInstance instance, CodeProcessor processor) {
    final fvbFuture = fvbClasses['Future']!.createInstance(processor, []);
    fvbFuture.variables['future']!.value = Future(() async {
      instance.variables['_dart'] = await future;
      return instance;
    });
    future.then((value) {
      fvbFuture.variables['value']!.value = value;
      (fvbFuture.variables['onValue']?.value as FVBFunction)
          .execute(processor, [value]);
    }).onError((error, stackTrace) {
      (fvbFuture.variables['onError']?.value as FVBFunction)
          .execute(processor, [error, stackTrace]);
    });
    return fvbFuture;
  }
}

class DurationConverter extends FVBConverter<Duration> {
  @override
  void fromDart(String name, List<dynamic> instances) {
    // TODO: implement fromDart
  }

  @override
  Duration toDart(FVBInstance instance) {
    return Duration(
      milliseconds: instance.variables['milliseconds']!.value,
      seconds: instance.variables['seconds']!.value,
      minutes: instance.variables['minutes']!.value,
      hours: instance.variables['hours']!.value,
      days: instance.variables['days']!.value,
    );
  }
}

class ColorConverter extends FVBConverter<Color> {
  @override
  void fromDart(String name, List<dynamic> instances) {}

  @override
  Color toDart(FVBInstance instance) {
    return Color(instance.variables['value']!.value);
  }
}

class PaintConverter extends FVBConverter<Paint> {
  @override
  void fromDart(String name, List<dynamic> instances) {}

  @override
  Paint toDart(FVBInstance instance) {
    final painter=Paint();
    if(instance.variables['color']!.value!=null) {
      painter.color = instance.variables['color']!.value;
      print('Color ${painter.color}');
    }
    if(instance.variables['strokeWidth']!.value!=null) {
      painter.strokeWidth = instance.variables['strokeWidth']!.value;
    }
    if(instance.variables['strokeCap']!.value!=null) {
      painter.strokeCap = instance.variables['strokeCap']!.value;
    }
    if(instance.variables['strokeJoin']!.value!=null) {
      painter.strokeWidth = instance.variables['strokeJoin']!.value;
    }
  return painter;
  }
}

class OffsetConverter extends FVBConverter<Offset> {
  @override
  Offset toDart(FVBInstance instance) {
    return Offset(
        convert(instance.variables['dx']), convert(instance.variables['dy']));
  }

  @override
  void fromDart(String name, List<dynamic> instances) {
    // TODO: implement fromDart
  }
}

class RectConverter extends FVBConverter<Rect> {
  @override
  Rect toDart(FVBInstance instance) {
    return Rect.fromLTRB(
        instance.variables['left']!.value.toDouble(),
        instance.variables['top']!.value.toDouble(),
        instance.variables['right']!.value.toDouble(),
        instance.variables['bottom']!.value.toDouble());
  }

  @override
  void fromDart(String name, List<dynamic> instances) {
    switch (name) {
      case 'fromPoints':
        Rect.fromPoints(instances[0], instances[1]);
        break;
    }
  }
}
