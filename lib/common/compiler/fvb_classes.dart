import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/variable_model.dart';
import 'code_processor.dart';
import 'fvb_converter.dart';

class FVBModuleClasses {
  static Map<String, FVBEnum> fvbEnums = {
    'PointMode': FVBEnum(
      'PointMode',
      {
        'points': FVBEnumValue('points', 0, 'PointMode'),
        'lines': FVBEnumValue('lines', 1, 'PointMode'),
        'polygon': FVBEnumValue('polygon', 2, 'PointMode'),
      },
    ),
  };
  static Map<String, FVBClass> fvbClasses = {
    'Size': FVBClass.create('Size', vars: {
      'width': () => FVBVariable('width', DataType.fvbDouble),
      'height': () => FVBVariable('height', DataType.fvbDouble),
    }, funs: [
      FVBFunction('Size', '', [
        FVBArgument('this.width', dataType: DataType.fvbDouble),
        FVBArgument('this.height', dataType: DataType.fvbDouble),
      ])
    ]),
    'Radius': FVBClass.create(
      'Radius',
    ),
    'RRect': FVBClass.create('RRect', vars: {
      'rect': () => FVBVariable('rect', DataType.fvbInstance('Rect')),
      'tlRadius': () => FVBVariable('tlRadius', DataType.fvbDouble),
      'trRadius': () => FVBVariable('trRadius', DataType.fvbDouble),
      'blRadius': () => FVBVariable('blRadius', DataType.fvbDouble),
      'brRadius': () => FVBVariable('brRadius', DataType.fvbDouble),
    }, funs: [
      FVBFunction(
          'RRect',
          'fromRectAndCorners',
          [
            FVBArgument('this.rect', dataType: DataType.fvbInstance('Rect')),
            FVBArgument('this.tlRadius', dataType: DataType.fvbDouble),
            FVBArgument('this.trRadius', dataType: DataType.fvbDouble),
            FVBArgument('this.blRadius', dataType: DataType.fvbDouble),
            FVBArgument('this.brRadius', dataType: DataType.fvbDouble),
          ],
          dartCall: (args, instance) =>
              (args.last as CodeProcessor).variables['_dart'] =
                  FVBVariable('_dart', DataType.dynamic,
                      value: RRect.fromRectAndCorners(
                        (args[0] as FVBInstance).toDart(),
                      )))
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
    'Offset': FVBClass.create(
      'Offset',
      funs: [
        FVBFunction(
          'Offset',
          null,
          [
            FVBArgument('this.dx', dataType: DataType.fvbDouble),
            FVBArgument('this.dy', dataType: DataType.fvbDouble)
          ],
          dartCall: (args, instance) =>
              (args.last as CodeProcessor).variables['_dart'] = FVBVariable(
            '_dart',
            DataType.dynamic,
            value: Offset(args[0], args[1]),
          ),
        ),
      ],
      vars: {
        'dx': () => FVBVariable('dx', DataType.fvbDouble),
        'dy': () => FVBVariable('dy', DataType.fvbDouble),
      },
    ),
    'TextField': FVBClass('TextField', {
      'setText': FVBFunction('setText', null, [FVBArgument('text')]),
      'clear': FVBFunction('clear', '', []),
    }, {
      'text': () => FVBVariable('text', DataType.string),
    }),
    'PageView': FVBClass('PageView', {
      'setPage': FVBFunction('setPage', null, [FVBArgument('page')]),
    }, {
      'controller': () => FVBVariable(
            'controller',
            DataType.fvbInstance('PageController'),
          ),
    }),
    'PageController': FVBClass.create('PageController', vars: {
      '_dart': () => FVBVariable('_dart', DataType.dynamic),
    }, funs: [
      FVBFunction(
          'jumpToPage', null, [FVBArgument('index', dataType: DataType.fvbInt)],
          dartCall: (args, instance) {
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          (instance?.variables['_dart']?.value as PageController?)
              ?.jumpToPage(args[0]);
        }
        // (args[])
      }),
      FVBFunction('animateToPage', null, [
        FVBArgument('index', dataType: DataType.fvbInt),
        FVBArgument('duration',
            type: FVBArgumentType.optionalNamed, nullable: false),
        FVBArgument('curve',
            type: FVBArgumentType.optionalNamed, nullable: false)
      ], dartCall: (args, instance) {
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          (instance?.variables['_dart']?.value as PageController?)
              ?.animateToPage(
            args[0],
            duration: (args[1] as FVBInstance).toDart(),
            curve: (args[2] as Curve),
          );
        }
        // (args[])
      }),
    ]),
    'Curves': FVBClass.create('Curves', staticVars: [
      FVBVariable('ease', DataType.fvbInstance('Curve'), value: Curves.ease),
      FVBVariable('easeInOut', DataType.fvbInstance('Curve'),
          value: Curves.easeInOut),
      FVBVariable('easeIn', DataType.fvbInstance('Curve'),
          value: Curves.easeIn),
      FVBVariable('easeOut', DataType.fvbInstance('Curve'),
          value: Curves.easeOut),
      FVBVariable('easeInCubic', DataType.fvbInstance('Curve'),
          value: Curves.easeInCubic),
      FVBVariable('easeOutCubic', DataType.fvbInstance('Curve'),
          value: Curves.easeOutCubic),
      FVBVariable('easeInOutCubic', DataType.fvbInstance('Curve'),
          value: Curves.easeInOutCubic),
      FVBVariable('easeInQuart', DataType.fvbInstance('Curve'),
          value: Curves.easeInQuart),
      FVBVariable('easeOutQuart', DataType.fvbInstance('Curve'),
          value: Curves.easeOutQuart),
      FVBVariable('easeInOutQuart', DataType.fvbInstance('Curve'),
          value: Curves.easeInOutQuart),
      FVBVariable('easeInQuint', DataType.fvbInstance('Curve'),
          value: Curves.easeInQuint),
      FVBVariable('easeOutQuint', DataType.fvbInstance('Curve'),
          value: Curves.easeOutQuint),
      FVBVariable('easeInOutQuint', DataType.fvbInstance('Curve'),
          value: Curves.easeInOutQuint),
      FVBVariable('easeInSine', DataType.fvbInstance('Curve'),
          value: Curves.easeInSine),
      FVBVariable('easeOutSine', DataType.fvbInstance('Curve'),
          value: Curves.easeOutSine),
      FVBVariable('easeInOutSine', DataType.fvbInstance('Curve'),
          value: Curves.easeInOutSine),
      FVBVariable('easeInExpo', DataType.fvbInstance('Curve'),
          value: Curves.easeInExpo),
      FVBVariable('easeOutExpo', DataType.fvbInstance('Curve'),
          value: Curves.easeOutExpo),
      FVBVariable('easeInOutExpo', DataType.fvbInstance('Curve'),
          value: Curves.easeInOutExpo),
      FVBVariable('easeInCirc', DataType.fvbInstance('Curve'),
          value: Curves.easeInCirc),
      FVBVariable('easeOutCirc', DataType.fvbInstance('Curve'),
          value: Curves.easeOutCirc),
      FVBVariable('easeInOutCirc', DataType.fvbInstance('Curve'),
          value: Curves.easeInOutCirc),
      FVBVariable('easeInBack', DataType.fvbInstance('Curve'),
          value: Curves.easeInBack),
      FVBVariable('easeOutBack', DataType.fvbInstance('Curve'),
          value: Curves.easeOutBack),
      FVBVariable('easeInOutBack', DataType.fvbInstance('Curve'),
          value: Curves.easeInOutBack),
      FVBVariable('linear', DataType.fvbInstance('Curve'),
          value: Curves.linear),
      FVBVariable('fastOutSlowIn', DataType.fvbInstance('Curve'),
          value: Curves.fastOutSlowIn),
      FVBVariable('bounceIn', DataType.fvbInstance('Curve'),
          value: Curves.bounceIn),
      FVBVariable('bounceOut', DataType.fvbInstance('Curve'),
          value: Curves.bounceOut),
      FVBVariable('bounceInOut', DataType.fvbInstance('Curve'),
          value: Curves.bounceInOut),
      FVBVariable('elasticIn', DataType.fvbInstance('Curve'),
          value: Curves.elasticIn),
      FVBVariable('elasticOut', DataType.fvbInstance('Curve'),
          value: Curves.elasticOut),
      FVBVariable('elasticInOut', DataType.fvbInstance('Curve'),
          value: Curves.elasticInOut),
      FVBVariable('slowMiddle', DataType.fvbInstance('Curve'),
          value: Curves.slowMiddle),
    ]),
    'Utils': FVBClass.create('Utils', staticFuns: [
      FVBFunction('postFrameCallback', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction)
      ], dartCall: (args, instance) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          (args[0] as FVBFunction).execute(args.last, instance, [timeStamp]);
        });
      }),
    ]),
    'Future': FVBClass('Future', {
      'Future.delayed': FVBFunction('Future.delayed', '', [
        FVBArgument('duration', dataType: DataType.fvbInstance('Duration')),
        FVBArgument('computation',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbFunction,
            nullable: true)
      ], dartCall: (args, instance) {
        final processor = args[2] as CodeProcessor;
        final fvbFuture = fvbClasses['Future']!.createInstance(processor, []);
        if (CodeProcessor.operationType == OperationType.checkOnly &&
            args.length > 1) {
          (args[1] as FVBFunction?)?.execute(processor, instance, []);
        } else {
          fvbFuture.variables['future']!.value = Future.delayed(
              (args[0] as FVBInstance).toDart(),
              args[1] != null
                  ? () async {
                      if (CodeProcessor.error || processor.finished) {
                        return;
                      }
                      final result = await (args[1] as FVBFunction)
                          .execute(processor, instance, []);
                      (fvbFuture.variables['onValue']?.value as FVBFunction?)
                          ?.execute(processor, instance, [result]);
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
          dartCall: (arguments, instance) {
        final preferences = fvbClasses['SharedPreferences']!
            .createInstance(arguments.last as CodeProcessor, []);
        final fvbFuture = fvbClasses['Future']!.createInstance(
            arguments.last, [],
            generics: [DataType.fvbInstance(preferences.fvbClass.name)]);
        fvbFuture.variables['future']!.value = Future<FVBInstance>(() async {
          final pref = await SharedPreferences.getInstance();
          preferences.variables['_pref']!.value = pref;
          fvbFuture.variables['value']!.value = preferences;
          (fvbFuture.variables['onValue']?.value as FVBFunction?)?.execute(
              arguments.last as CodeProcessor, instance, [preferences]);
          return preferences;
        });

        return fvbFuture;
      }, isFactory: true),
      FVBFunction('setInt', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbInt),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setInt(arguments[0] as String, arguments[1] as int);
        }
      }),
      FVBFunction('setString', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setString(arguments[0] as String, arguments[1] as String);
        }
      }),
      FVBFunction('setBool', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbBool),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setBool(arguments[0] as String, arguments[1] as bool);
        }
      }),
      FVBFunction('setDouble', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbDouble),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setDouble(arguments[0] as String, arguments[1] as double);
        }
      }),
      FVBFunction('setStringList', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.list(DataType.string)),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          pref?.setStringList(
              arguments[0] as String, arguments[1] as List<String>);
        }
      }),
      FVBFunction('getInt', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getInt(arguments[0] as String);
        }
        return FVBTest(DataType.fvbInt, false);
      }),
      FVBFunction('getString', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getString(arguments[0] as String);
        }
        return FVBTest(DataType.string, false);
      }),
      FVBFunction('getBool', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getBool(arguments[0] as String);
        }
        return FVBTest(DataType.fvbBool, false);
      }),
      FVBFunction('getDouble', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getDouble(arguments[0] as String);
        }
        return FVBTest(DataType.fvbDouble, false);
      }),
      FVBFunction('getStringList', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref?.getStringList(arguments[0] as String);
        }
        return FVBTest(DataType.list(null), false);
      }),
      FVBFunction(
          'containsKey',
          null,
          [
            FVBArgument('key', dataType: DataType.string),
          ],
          returnType: DataType.fvbBool, dartCall: (arguments, instance) {
        final processor = arguments[1] as CodeProcessor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (CodeProcessor.operationType != OperationType.checkOnly) {
          return pref!.containsKey(arguments[0] as String);
        }
        return FVBTest(DataType.fvbBool, false);
      }),
      FVBFunction('clear', null, [], isAsync: true, returnType: DataType.future,
          dartCall: (arguments, instance) {
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
        ..dartCall = (arguments, instance) async {
          return (await http.get(arguments[0])).body;
        },
    }, {}),
    'int': FVBClass('int', {}, {}, fvbStaticFunctions: {
      'parse': FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments, instance) => arguments[0] is FVBTest
            ? FVBTest(DataType.fvbInt, false)
            : int.parse(arguments[0])
    }),
    'double': FVBClass('double', {}, {}, fvbStaticFunctions: {
      'parse': FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments, instance) => arguments[0] is FVBTest
            ? FVBTest(DataType.fvbInt, false)
            : double.parse(arguments[0])
    }),
    'Duration': FVBClass(
        'Duration',
        {
          'Duration': FVBFunction('Duration', '', [
            //microseconds
            FVBArgument('this.microseconds',
                type: FVBArgumentType.optionalNamed, defaultVal: 0),
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
          ], dartCall: (args, instance) {
            (args[args.length - 2] as FVBInstance).variables['_dart'] =
                FVBVariable(
                    '_dart', DataType.dynamic,
                    value: fromInstanceToDuration(
                        (args[args.length - 2] as FVBInstance).variables));
            return null;
          }),
        },
        {
          'microseconds': () => VariableModel('microseconds', DataType.fvbInt),
          'milliseconds': () => VariableModel('milliseconds', DataType.fvbInt),
          'seconds': () => VariableModel('seconds', DataType.fvbInt),
          'minutes': () => VariableModel('minutes', DataType.fvbInt),
          'hours': () => VariableModel('hours', DataType.fvbInt),
          'days': () => VariableModel('days', DataType.fvbInt),
        },
        converter: DurationConverter()),
    'PaintingStyle': FVBClass.create('PaintingStyle', staticVars: [
      FVBVariable(
        'fill',
        DataType.fvbBool,
        getCall: (value, processor) => PaintingStyle.fill,
      ),
      FVBVariable(
        'stroke',
        DataType.fvbBool,
        getCall: (value, processor) => PaintingStyle.stroke,
      ),
    ]),
    'Paint': FVBClass.create('Paint',
        vars: {
          'color': () => FVBVariable('color', DataType.fvbInstance('Color')),
          'strokeWidth': () => FVBVariable('strokeWidth', DataType.fvbDouble),
          'strokeCap': () => FVBVariable('strokeCap', DataType.string),
          'strokeJoin': () => FVBVariable('strokeJoin', DataType.string),
          'style': () =>
              FVBVariable('style', DataType.fvbInstance('PaintingStyle')),
        },
        converter: PaintConverter()),
    'Color': FVBClass.create('Color',
        vars: {
          'value': () => FVBVariable('value', DataType.fvbInt),
        },
        funs: [
          FVBFunction('Color', '', [
            FVBArgument('this.value', type: FVBArgumentType.placed)
          ], dartCall: (arguments, instance) {
            (arguments.last as CodeProcessor).variables['_dart'] = FVBVariable(
                '_dart', DataType.dynamic,
                value: Color(arguments[0] as int));
            return null;
          }),
          //withOpacity
          FVBFunction('withOpacity', null, [
            FVBArgument('opacity',
                dataType: DataType.fvbDouble, type: FVBArgumentType.placed)
          ], dartCall: (arguments, instance) {
            final processor = arguments.last as CodeProcessor;
            return fvbClasses['Color']!.createInstance(arguments.last, [
              (processor.variables['_dart']!.value as Color)
                  .withOpacity(arguments[0] as double)
                  .value
            ]);
          }),
          //withAlpha
          FVBFunction('withAlpha', '', [
            FVBArgument('this.alpha', type: FVBArgumentType.placed)
          ], dartCall: (arguments, instance) {
            final processor = arguments.last as CodeProcessor;
            return fvbClasses['Color']!.createInstance(arguments.last, [
              (processor.variables['_dart']!.value as Color)
                  .withAlpha(arguments[0] as int)
                  .value
            ]);
          }),
        ],
        converter: ColorConverter()),
    'Colors': FVBClass.create('Colors', staticVars: [
      FVBVariable(
        'black',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black.value]),
      ),
      FVBVariable(
        'red',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) =>
            fvbClasses['Color']!.createInstance(processor, [Colors.red.value]),
      ),
      FVBVariable(
        'green',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.green.value]),
      ),
      FVBVariable(
        'blue',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) =>
            fvbClasses['Color']!.createInstance(processor, [Colors.blue.value]),
      ),
      //blueaccent
      FVBVariable(
        'cyan',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) =>
            fvbClasses['Color']!.createInstance(processor, [Colors.cyan.value]),
      ),
      FVBVariable(
        'teal',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) =>
            fvbClasses['Color']!.createInstance(processor, [Colors.teal.value]),
      ),
      FVBVariable(
        'greenAccent',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.greenAccent.value]),
      ),
      //blueaccent
      FVBVariable(
        'blueAccent',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.blueAccent.value]),
      ),
      FVBVariable(
        'indigo',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.indigo.value]),
      ),

      FVBVariable(
        'lightGreen',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.lightGreen.value]),
      ),
      FVBVariable(
        'lime',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) =>
            fvbClasses['Color']!.createInstance(processor, [Colors.lime.value]),
      ),
      FVBVariable(
        'yellow',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.yellow.value]),
      ),
      FVBVariable(
        'amber',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.amber.value]),
      ),
      FVBVariable(
        'orange',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.orange.value]),
      ),
      FVBVariable(
        'deepOrange',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.deepOrange.value]),
      ),
      FVBVariable(
        'brown',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.brown.value]),
      ),

      FVBVariable(
        'white',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.white.value]),
      ),
      FVBVariable(
        'grey',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) =>
            fvbClasses['Color']!.createInstance(processor, [Colors.grey.value]),
      ),
      FVBVariable(
        'black87',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black87.value]),
      ),
      FVBVariable(
        'black54',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black54.value]),
      ),
      FVBVariable(
        'black45',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black45.value]),
      ),
      FVBVariable(
        'black38',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black38.value]),
      ),
      FVBVariable(
        'black26',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black26.value]),
      ),
      FVBVariable(
        'black12',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black12.value]),
      ),
      //purple
      FVBVariable(
        'purple',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.purple.value]),
      ),
      FVBVariable(
        'purpleAccent',
        DataType.fvbInstance('Color'),
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.purpleAccent.value]),
      ),
    ]),
    /**
        canvasClass.fvbFunctions['drawPoint']!.dartCall = (arguments) {
        Paint()..color = Colors.red);
        canvas.drawRect(Rect.fromPoints(Offset(0, 0), Offset(100, 100)),

        };

        canvasClass.fvbFunctions['drawRect']!.dartCall = (arguments) {
        };
     **/
    'Canvas': FVBClass.create('Canvas', funs: [
      FVBFunction('Canvas', '', [FVBArgument('this._self')]),
      FVBFunction('drawPoint', null, []),
      FVBFunction('drawRect', null, [
        FVBArgument('rect', dataType: DataType.fvbInstance('Rect')),
        FVBArgument('paint', dataType: DataType.fvbInstance('Paint')),
      ], dartCall: (arguments, instance) {
        final rect = (arguments[0] as FVBInstance?)?.toDart();
        final paint = (arguments[1] as FVBInstance?)?.toDart();
        if (CodeProcessor.operationType == OperationType.regular) {
          ((arguments[2] as CodeProcessor).variables['_self']!.value as Canvas)
              .drawRect(rect, paint);
        }
      }),
      FVBFunction('drawCircle', null, [
        FVBArgument('c', dataType: DataType.fvbInstance('Offset')),
        FVBArgument('radius', dataType: DataType.fvbNum),
        FVBArgument('paint', dataType: DataType.fvbInstance('Paint')),
      ], dartCall: (arguments, instance) {
        final c = (arguments[0] as FVBInstance?)?.toDart();
        final paint = (arguments[2] as FVBInstance?)?.toDart();
        if (CodeProcessor.operationType == OperationType.regular) {
          ((arguments[3] as CodeProcessor).variables['_self']!.value as Canvas)
              .drawCircle(c, arguments[1], paint);
        }
      }),
      //drawLine
      FVBFunction('drawLine', null, [
        FVBArgument('p1', dataType: DataType.fvbInstance('Offset')),
        FVBArgument('p2', dataType: DataType.fvbInstance('Offset')),
        FVBArgument('paint', dataType: DataType.fvbInstance('Paint')),
      ], dartCall: (arguments, instance) {
        final p1 = (arguments[0] as FVBInstance?)?.toDart();
        final p2 = (arguments[1] as FVBInstance?)?.toDart();
        final paint = (arguments[2] as FVBInstance?)?.toDart();
        if (CodeProcessor.operationType == OperationType.regular) {
          ((arguments[3] as CodeProcessor).variables['_self']!.value as Canvas)
              .drawLine(p1, p2, paint);
        }
      }),
      //drawPoints
      FVBFunction('drawPoints', null, [
        FVBArgument('mode', dataType: DataType.fvbEnum('PointMode')),
        FVBArgument('points',
            dataType: DataType.list(DataType.fvbInstance('Offset'))),
        FVBArgument('paint', dataType: DataType.fvbInstance('Paint')),
      ], dartCall: (arguments, instance) {
        final mode = PointMode.values[(arguments[0] as FVBEnumValue).index];
        final points = (arguments[1] as List<dynamic>)
            .map<Offset>((e) => e.toDart())
            .toList(growable: false);
        final paint = (arguments[2] as FVBInstance?)?.toDart();
        if (CodeProcessor.operationType == OperationType.regular) {
          ((arguments.last as CodeProcessor).variables['_self']!.value
                  as Canvas)
              .drawPoints(mode, points, paint);
        }
      }),
    ], vars: {
      '_self': () => FVBVariable('_self', DataType.dynamic),
    }),
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
            ..dartCall = (arguments, instance) {
              final timerInstance = fvbClasses['Timer']!
                  .createInstance(arguments[2], arguments.sublist(0, 2));

              if (CodeProcessor.operationType == OperationType.checkOnly) {
                (arguments[1] as FVBFunction)
                    .execute(arguments[2], instance, [timerInstance]);
                timerInstance.fvbClass.fvbFunctions['cancel']!.dartCall =
                    (args, instance) {};
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
                      .execute(arguments[2], instance, [timerInstance]);
                });
                CodeProcessor.timers.add(timer);
                timerInstance.fvbClass.fvbFunctions['cancel']!.dartCall =
                    (args, instance) {
                  timer.cancel();
                  CodeProcessor.timers.remove(timer);
                };
              }

              return timerInstance;
            },
        },
        parent: null),
    'String': FVBClass.create('String', vars: {
      'length': () => FVBVariable(
            'length',
            DataType.string,
            getCall: (object, processor) => (object as String).length,
          ),
    }, funs: [
      FVBFunction('substring', null, [
        FVBArgument('start',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
        FVBArgument('end',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            nullable: true)
      ], dartCall: (args, instance) {
        return (args[0] as String).substring(args[1] as int, args[2] as int?);
      }),
      FVBFunction('toUpperCase', null, [], dartCall: (args, instance) {
        return (args[0] as String).toUpperCase();
      }),
      FVBFunction('toLowerCase', null, [], dartCall: (args, instance) {
        return (args[0] as String).toLowerCase();
      }),
      FVBFunction('indexOf', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('start',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            defaultVal: 0),
      ], dartCall: (args, instance) {
        return (args[0] as String).indexOf(args[1] as String, args[2] as int);
      }),
      FVBFunction('lastIndexOf', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('start',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            defaultVal: 0),
      ], dartCall: (args, instance) {
        return (args[0] as String)
            .lastIndexOf(args[1] as String, args[2] as int);
      }),
      FVBFunction('replace', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('replace',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        return (args[0] as String)
            .replaceAll(args[1] as String, args[2] as String);
      }),
      FVBFunction(
          'split',
          null,
          [
            FVBArgument('separator',
                type: FVBArgumentType.optionalPlaced,
                dataType: DataType.string,
                defaultVal: ''),
          ],
          returnType: DataType.iterable(null), dartCall: (args, instance) {
        return (args[0] as String).split(args[1] as String);
      }),
      FVBFunction('trim', null, [], dartCall: (args, instance) {
        return (args[0] as String).trim();
      }),
      FVBFunction('trimLeft', null, [], dartCall: (args, instance) {
        return (args[0] as String).trimLeft();
      }),
      FVBFunction('trimRight', null, [], dartCall: (args, instance) {
        return (args[0] as String).trimRight();
      }),
      //replaceAll
      FVBFunction('replaceAll', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('replace',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        return (args[0] as String)
            .replaceAll(args[1] as String, args[2] as String);
      }),
      //replaceFirst
      FVBFunction('replaceFirst', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
        FVBArgument('replace',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        return (args[0] as String)
            .replaceFirst(args[1] as String, args[2] as String);
      }),
      //contains
      FVBFunction('contains', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        return (args[0] as String).contains(args[1] as String);
      }),
      //startsWith
      FVBFunction('startsWith', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        return (args[0] as String).startsWith(args[1] as String);
      }),
      //endsWith
      FVBFunction('endsWith', null, [
        FVBArgument('search',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        return (args[0] as String).endsWith(args[1] as String);
      }),
      //replaceRange
      FVBFunction('replaceRange', null, [
        FVBArgument('start',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
        FVBArgument('end',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
        FVBArgument('replace',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        return (args[0] as String)
            .replaceRange(args[1] as int, args[2] as int, args[3] as String);
      }),
    ]),
    'List': FVBClass.create('List', vars: {
      'length': () => FVBVariable(
            'length',
            DataType.fvbInt,
            getCall: (object, processor) => (object as List).length,
          ),
    }, funs: [
      FVBFunction('add', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args, instance) {
        if (args[0] is List) {
          (args[0] as List).add(args[1] as dynamic);
        }
        return args[1];
      }),
      FVBFunction('remove', null, [
        FVBArgument('index',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      ], dartCall: (args, instance) {
        (args[0] as List).removeAt(args[1] as int);
        return args[1];
      }),
      FVBFunction('insert', null, [
        FVBArgument('index',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args, instance) {
        (args[0] as List).insert(args[1] as int, args[2] as dynamic);
        return args[1];
      }),
      FVBFunction('removeAt', null, [
        FVBArgument('index',
            type: FVBArgumentType.placed, dataType: DataType.fvbInt),
      ], dartCall: (args, instance) {
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
        (args[0] as List).removeRange(args[1] as int, args[2] as int);
        return args[1];
      }),
      FVBFunction('clear', null, [], dartCall: (args, instance) {
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
              .execute(args.last as CodeProcessor, instance, [e]);
        }).toList();
      }),
      FVBFunction('contains', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args, instance) {
        return (args[0] as List).contains(args[1] as dynamic);
      }),
      FVBFunction('indexOf', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
        FVBArgument('start',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbInt,
            defaultVal: 0),
      ], dartCall: (args, instance) {
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
          (args[1] as FVBFunction)
              .execute(args.last as CodeProcessor, instance, [e]);
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
              .execute(args.last as CodeProcessor, instance, [e]);
        }).toList();
      }),
      //remove where
      FVBFunction('removeWhere', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
      ], dartCall: (args, instance) {
        (args[0] as List).removeWhere((e) {
          return (args[1] as FVBFunction)
              .execute(args.last as CodeProcessor, instance, [e]);
        });
        return null;
      }),
      //add all
      FVBFunction('addAll', null, [
        FVBArgument('elements',
            type: FVBArgumentType.placed, dataType: DataType.iterable(null)),
      ], dartCall: (args, instance) {
        (args[0] as List).addAll(args[1] as Iterable);
        return null;
      }),
    ]),
    'Iterable': FVBClass.create('Iterable', vars: {
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
        return (args[0] as Iterable).map((e) {
          return (args[1] as FVBFunction)
              .execute(args.last as CodeProcessor, instance, [e]);
        }).toList();
      }),
      FVBFunction('contains', null, [
        FVBArgument('element',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args, instance) {
        return (args[0] as Iterable).contains(args[1] as dynamic);
      }),
      //aslist
      FVBFunction('asList', null, [], returnType: DataType.list(null),
          dartCall: (args, instance) {
        return (args[0] as Iterable).toList();
      }),
    ]),
    'Map': FVBClass.create('Map', vars: {
      'length': () => FVBVariable(
            'length',
            DataType.fvbInt,
            getCall: (object, processor) => (object as Map).length,
          ),
    }, funs: [
      FVBFunction('addAll', null, [
        FVBArgument('map',
            type: FVBArgumentType.placed, dataType: DataType.map([])),
      ], dartCall: (args, instance) {
        (args[0] as Map).addAll(args[1] as Map);
        return args[1];
      }),
      FVBFunction('remove', null, [
        FVBArgument('key',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args, instance) {
        (args[0] as Map).remove(args[1] as dynamic);
        return args[1];
      }),
      FVBFunction('containsKey', null, [
        FVBArgument('key',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args, instance) {
        return (args[0] as Map).containsKey(args[1] as dynamic);
      }),
      FVBFunction('containsValue', null, [
        FVBArgument('value',
            type: FVBArgumentType.placed, dataType: DataType.dynamic),
      ], dartCall: (args, instance) {
        return (args[0] as Map).containsValue(args[1] as dynamic);
      }),
      FVBFunction('clear', null, [], dartCall: (args, instance) {
        (args[0] as Map).clear();
      }),
      FVBFunction('forEach', null, [
        FVBArgument('callback',
            type: FVBArgumentType.placed, dataType: DataType.fvbFunction),
      ], dartCall: (args, instance) {
        (args[0] as Map).forEach((k, v) {
          (args[1] as FVBFunction)
              .execute(args.last as CodeProcessor, instance, [k, v]);
        });
      })
    ]),
    'DateTime': FVBClass('DateTime', {
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
        FVBArgument('this.microsecond',
            type: FVBArgumentType.optionalPlaced, defaultVal: 0),
      ], dartCall: (args, instance) {
        final instance = (args[args.length - 2] as FVBInstance);
        final dateTime = fromInstanceToDateTime(instance.variables);
        instance.variables['_dart'] =
            FVBVariable('_dart', DataType.dynamic, value: dateTime);
        return dateTime;
      }),
      'toLocal': FVBFunction('toLocal', null, [], dartCall: (args, instance) {
        return fromDateTimeToInstance(
            ((args.last as CodeProcessor).variables['_dart']!.value as DateTime)
                .toLocal(),
            args.last);
      }),
      'toUtc': FVBFunction('toUtc', null, [], dartCall: (args, instance) {
        return fromDateTimeToInstance(
            ((args.last as CodeProcessor).variables['_dart']!.value as DateTime)
                .toUtc(),
            args.last);
      }),

      //isBefore
      'isBefore': FVBFunction(
          'isBefore',
          null,
          [
            FVBArgument('other',
                type: FVBArgumentType.placed,
                dataType: DataType.fvbInstance('DateTime')),
          ],
          returnType: DataType.fvbBool, dartCall: (args, instance) {
        return ((args.last as CodeProcessor).variables['_dart']!.value
                as DateTime)
            .isBefore(
                (args[0] as FVBInstance).variables['_dart']!.value as DateTime);
      }),
      //isAfter
      'isAfter': FVBFunction(
          'isAfter',
          null,
          [
            FVBArgument('other',
                type: FVBArgumentType.placed,
                dataType: DataType.fvbInstance('DateTime')),
          ],
          returnType: DataType.fvbBool, dartCall: (args, instance) {
        return ((args.last as CodeProcessor).variables['_dart']!.value
                as DateTime)
            .isAfter(
                (args[0] as FVBInstance).variables['_dart']!.value as DateTime);
      }),
      //difference
      'difference': FVBFunction(
          'difference',
          null,
          [
            FVBArgument('other',
                type: FVBArgumentType.placed,
                dataType: DataType.fvbInstance('DateTime')),
          ],
          returnType: DataType.fvbInstance('DateTime'),
          dartCall: (args, instance) {
        return ((args.last as CodeProcessor).variables['_dart']!.value
                as DateTime)
            .difference(
                (args[0] as FVBInstance).variables['_dart']!.value as DateTime);
      }),
      'toString': FVBFunction('toString', null, [], dartCall: (args, instance) {
        final processor = args.last as CodeProcessor;
        return (processor.variables['_dart']!.value as DateTime).toString();
      }),
      'add': FVBFunction('add', null, [
        FVBArgument(
          'duration',
          type: FVBArgumentType.placed,
          dataType: DataType.fvbInstance('Duration'),
        ),
      ], dartCall: (args, instance) {
        final processor = args.last as CodeProcessor;
        return fromDateTimeToInstance(
            (processor.variables['_dart']!.value as DateTime)
                .add((args[0] as FVBInstance).variables['_dart']!.value),
            processor);
      }),
    }, {
      'year': () => FVBVariable('year', DataType.fvbInt),
      'month': () => FVBVariable('month', DataType.fvbInt),
      'day': () => FVBVariable('day', DataType.fvbInt),
      'hour': () => FVBVariable('hour', DataType.fvbInt),
      'minute': () => FVBVariable('minute', DataType.fvbInt),
      'second': () => FVBVariable('second', DataType.fvbInt),
      'millisecond': () => FVBVariable('millisecond', DataType.fvbInt),
      'microsecond': () => FVBVariable('microsecond', DataType.fvbInt),
      'isUtc': () => FVBVariable('isUtc', DataType.fvbBool,
          getCall: (object, processor) => (object as DateTime).isUtc),
      //millisecondsSinceEpoch
      'millisecondsSinceEpoch': () => FVBVariable(
          'millisecondsSinceEpoch', DataType.fvbInt,
          getCall: (object, processor) =>
              (object as DateTime).millisecondsSinceEpoch),
      'microsecondsSinceEpoch': () => FVBVariable(
          'microsecondsSinceEpoch', DataType.fvbInt,
          getCall: (object, processor) =>
              (object as DateTime).microsecondsSinceEpoch),
    }, fvbStaticFunctions: {
      'now': FVBFunction('now', null, [])
        ..dartCall = (arguments, instance) {
          return fromDateTimeToInstance(DateTime.now(), arguments.last);
        },
    }),
    //DateFormat
    'DateFormat': FVBClass('DateFormat', {
      'DateFormat': FVBFunction('DateFormat', '', [
        FVBArgument('this.pattern',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        (args[args.length - 2] as FVBInstance).variables['_dart'] = FVBVariable(
            '_dart', DataType.dynamic,
            value: DateFormat(args[0] as String));
        return null;
      }),
      'format': FVBFunction('format', null, [
        FVBArgument('date',
            type: FVBArgumentType.placed,
            dataType: DataType.fvbInstance('DateTime')),
      ], dartCall: (args, instance) {
        if (CodeProcessor.operationType == OperationType.checkOnly) {
          return '';
        }
        final instance = (args.last as CodeProcessor);
        final dateFormat = instance.variables['_dart']!.value as DateFormat;
        return dateFormat
            .format((args[0] as FVBInstance).variables['_dart']!.value);
      }),
      'parse': FVBFunction('parse', null, [
        FVBArgument('string',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        if (CodeProcessor.operationType == OperationType.checkOnly) {
          return fromDateTimeToInstance(
              DateTime(0), (args.last as CodeProcessor));
        }
        final instance = (args.last as CodeProcessor);
        final dateFormat = instance.variables['_dart']!.value as DateFormat;
        return fromDateTimeToInstance(
            dateFormat.parse(args[0] as String), instance);
      }),
    }, {
      'pattern': () => FVBVariable('pattern', DataType.string),
    }),
  };

  FVBModuleClasses() {
    final time = DateTime.now();

    // Rect offset = Rect.fromPoints(a, b);
  }

  static FVBInstance fromDateTimeToInstance(
      DateTime dateTime, CodeProcessor processor) {
    return fvbClasses['DateTime']!.createInstance(processor, [
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    ])
      ..variables['_dart'] =
          FVBVariable('_dart', DataType.dynamic, value: dateTime);
  }

  static DateTime fromInstanceToDateTime(Map variables) {
    return DateTime(
      variables['year']!.value,
      variables['month']!.value,
      variables['day']!.value,
      variables['hour']!.value,
      variables['minute']!.value,
      variables['second']!.value,
      variables['millisecond']!.value,
      variables['microsecond']!.value,
    );
  }

  static Duration fromInstanceToDuration(Map variables) {
    return Duration(
      days: variables['days']!.value,
      hours: variables['hours']!.value,
      minutes: variables['minutes']!.value,
      seconds: variables['seconds']!.value,
      milliseconds: variables['milliseconds']!.value,
      microseconds: variables['microseconds']!.value,
    );
  }

  static FVBInstance createFVBFuture(
      Future future, FVBInstance instance, CodeProcessor processor) {
    final fvbFuture = fvbClasses['Future']!.createInstance(processor, []);
    fvbFuture.variables['future']!.value = Future(() async {
      instance.variables['_dart'] =
          FVBVariable('_dart', DataType.dynamic, value: await future);
      return instance;
    });
    future.then((value) {
      fvbFuture.variables['value']!.value = value;
      (fvbFuture.variables['onValue']?.value as FVBFunction)
          .execute(processor, instance, [value]);
    }).onError((error, stackTrace) {
      (fvbFuture.variables['onError']?.value as FVBFunction)
          .execute(processor, instance, [error, stackTrace]);
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
    final painter = Paint();
    if (instance.variables['color']!.value != null) {
      painter.color =
          (instance.variables['color']!.value as FVBInstance).toDart();
    }
    if (instance.variables['strokeWidth']!.value != null) {
      painter.strokeWidth = instance.variables['strokeWidth']!.value;
    }
    if (instance.variables['strokeCap']!.value != null) {
      painter.strokeCap = instance.variables['strokeCap']!.value;
    }
    if (instance.variables['strokeJoin']!.value != null) {
      painter.strokeWidth = instance.variables['strokeJoin']!.value;
    }
    if (instance.variables['style']!.value != null) {
      painter.style = instance.variables['style']!.value;
    }

    return painter;
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
