import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/variable_model.dart';
import 'code_processor.dart';
import 'package:http/http.dart' as http;

import 'fvb_converter.dart';

class FVBModuleClasses {
  static Map<String, FVBClass> fvbClasses = {
    'Size': FVBClass.create('Size', vars: {
      'width': () => FVBVariable('width', DataType.double),
      'height': () => FVBVariable('width', DataType.double),
    }),
    'Rect': FVBClass.create('Rect',
        vars: {
          'left': () => FVBVariable('left', DataType.double),
          'top': () => FVBVariable('top', DataType.double),
          'right': () => FVBVariable('right', DataType.double),
          'bottom': () => FVBVariable('bottom', DataType.double),
        },
        funs: [
          FVBFunction(
            'Rect.fromLTRB',
            '',
            [
              FVBArgument('this.left', dataType: DataType.double),
              FVBArgument('this.top', dataType: DataType.double),
              FVBArgument('this.right', dataType: DataType.double),
              FVBArgument('this.bottom', dataType: DataType.double),
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
              FVBArgument('this.dx', dataType: DataType.double),
              FVBArgument('this.dy', dataType: DataType.double)
            ],
          ),
        ],
        vars: {
          'dx': () => FVBVariable('dx', DataType.double),
          'dy': () => FVBVariable('dy', DataType.double),
        },
        converter: OffsetConverter()),
    'TextField': FVBClass('TextField', {
      'setText': FVBFunction('setText', null, [FVBArgument('text')]),
      'clear': FVBFunction('clear', '', []),
    }, {
      'text': () => FVBVariable('text', DataType.string),
    }),
    'Future': FVBClass('Future', {
      'Future.delayed': FVBFunction('Future.delayed', '', [], dartCall: (args) {}),
      'then': FVBFunction('then', 'onValue=value;', [FVBArgument('value')]),
      'onError':
          FVBFunction('onError', 'onError=error;', [FVBArgument('error')]),
    }, {
      'value': () => FVBVariable('value', DataType.dynamic),
      'onValue': () => FVBVariable('onValue', DataType.fvbFunction),
      'onError': () => FVBVariable('onError', DataType.fvbFunction),
    }),
    'SharedPreferences': FVBClass.create('SharedPreferences', funs: [
      FVBFunction('SharedPreferences.getInstance', null, [],
          dartCall: (arguments) {
        return SharedPreferences.getInstance();
      }),
      FVBFunction('setInt', null, []),
    ]),
    'Api': FVBClass('Api', {
      'get': FVBFunction('get', null, [FVBArgument('url')])
        ..dartCall = (arguments) async {
          return (await http.get(arguments[0])).body;
        },
    }, {}),
    'int': FVBClass('int', {}, {}, fvbStaticFunctions: {
      'parse': FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments) => int.parse(arguments[0])
    }),
    'double': FVBClass('double', {}, {}, fvbStaticFunctions: {
      'parse': FVBFunction('parse', null, [FVBArgument('text')])
        ..dartCall = (arguments) => double.parse(arguments[0])
    }),
    'Duration': FVBClass('Duration', {
      'Duration': FVBFunction('Duration', '', [
        FVBArgument('this.milliseconds', type: FVBArgumentType.optionalNamed),
      ]),
    }, {
      'milliseconds': () => VariableModel('milliseconds', DataType.int),
    }),
    'Paint': FVBClass.create('Paint', vars: {
      'color': () => FVBVariable('color', DataType.fvbInstance),
      'strokeWidth': () => FVBVariable('strokeWidth', DataType.double),
      'strokeCap': () => FVBVariable('strokeCap', DataType.string),
      'strokeJoin': () => FVBVariable('strokeJoin', DataType.string),
    }),
    'Color': FVBClass.create('Color',
        vars: {
          'value': () => FVBVariable('value', DataType.int),
        },
        funs: [
          FVBFunction('Color', '',
              [FVBArgument('this.value', type: FVBArgumentType.placed)])
        ],
        converter: ColorConverter()),
    'Canvas': FVBClass.create('Canvas', funs: [
      FVBFunction('drawPoint', null, []),
      FVBFunction('drawRect', null, [
        FVBArgument('rect', dataType: DataType.fvbInstance),
        FVBArgument('paint', dataType: DataType.fvbInstance)
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
        'year': () => FVBVariable('year', DataType.int),
        'month': () => FVBVariable('month', DataType.int),
        'day': () => FVBVariable('day', DataType.int),
        'hour': () => FVBVariable('hour', DataType.int),
        'minute': () => FVBVariable('minute', DataType.int),
        'second': () => FVBVariable('second', DataType.int),
        'millisecond': () => FVBVariable('millisecond', DataType.int),
      },
      //     fvbStaticFunctions: {
      //   'now': FVBFunction('now', null, [])
      //     ..dartCall = (arguments) => fvbClasses['DateTime'].createInstance(processor, arguments),
      // }
    ),
  };

  FVBModuleClasses() {
    SharedPreferences.getInstance();
    // Rect offset = Rect.fromPoints(a, b);
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
    return Paint()
      ..color = instance.variables['color']!.value
      ..strokeWidth = instance.variables['strokeWidth']!.value
      ..strokeCap = instance.variables['strokeCap']!.value
      ..strokeJoin = instance.variables['strokeJoin']!.value;
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
