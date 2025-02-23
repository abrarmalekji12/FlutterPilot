import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/bloc/api_bloc/api_bloc.dart';
import 'package:flutter_builder/bloc/navigation/fvb_navigation_bloc.dart';
import 'package:flutter_builder/code_operations.dart';
import 'package:flutter_builder/common/converter/string_operation.dart';
import 'package:flutter_builder/constant/string_constant.dart';
import 'package:flutter_builder/data/remote/firestore/firebase_bridge.dart';
import 'package:flutter_builder/data/remote/firestore/firebase_lib.dart';
import 'package:flutter_builder/injector.dart';
import 'package:flutter_builder/models/variable_model.dart';
import 'package:fvb_processor/compiler/fvb_functions.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'argument_list.dart';
import 'code_processor.dart';
import 'fvb_class.dart';
import 'fvb_converter.dart';
import 'fvb_dart_operations.dart';
import 'fvb_enums.dart';
import 'fvb_function_variables.dart';

final fvbColor = DataType.fvbInstance('Color');
final fvbApiClass = FVBClass.create(
  'Api',
);
final widgetClass = FVBClass.create(
  'Widget',
  vars: {},
);
final fvbMapStringDynamic =
    DataType.map([DataType.string, DataType.fvbDynamic]);
final fireStoreType = DataType.fvbInstance('FirebaseFirestore');
final docType = DataType.fvbInstance('DocumentReference');
final fvbQuerySnapshotType = DataType.fvbInstance('QuerySnapshot');
final fvbDocumentSnapshotType = DataType.fvbInstance('DocumentSnapshot');
final collectionRefType = DataType.fvbInstance('CollectionReference');
final FVBClass fvbQuerySnapshot = FVBClass.create('QuerySnapshot', vars: {
  '_instance': () => FVBVariable('_instance', DataType.dart('QuerySnapshot')),
  'docs': () => FVBVariable('docs', DataType.list(fvbDocumentSnapshotType),
          getCall: (data, processor) {
        if (Processor.operationType != OperationType.checkOnly) {
          final value =
              processor.variables['_instance']?.value as QuerySnapshot?;
          if (value != null) {
            return value.docs
                .map((e) => fvbDocumentSnapshot.createInstance(processor, [e]))
                .toList();
          }
        }
        return FVBTest(DataType.list(fvbDocumentSnapshotType), false);
      })
}, funs: [
  FVBFunction('QuerySnapshot', '', [FVBArgument('this._instance')]),
]);
final FVBClass firebaseFirestoreDoc =
    FVBClass.create('DocumentReference', vars: {
  '_instance': () =>
      FVBVariable('_instance', DataType.dart('DocumentReference')),
}, funs: [
  FVBFunction('DocumentReference', '', [FVBArgument('this._instance')]),
  FVBFunction('get', null, [],
      returnType: DataType.future(fvbDocumentSnapshotType),
      canReturnNull: false, dartCall: (args, self) {
    if (Processor.operationType != OperationType.checkOnly) {
      final value = self?.variables['_instance']?.value as DocumentReference?;
      if (value != null) {
        return createFVBFuture<DocumentSnapshot>(
            value.get(), 'DocumentSnapshot', (data) {
          return fvbDocumentSnapshot.createInstance(args.last, [data]);
        }, args.last, instanceName: '_instance');
      }
    }
    return FVBTest(DataType.future(fvbDocumentSnapshotType), false);
  }),
  FVBFunction('delete', null, [],
      returnType: DataType.future(DataType.fvbVoid),
      canReturnNull: false, dartCall: (args, self) {
    if (Processor.operationType != OperationType.checkOnly) {
      final value = self?.variables['_instance']?.value as DocumentReference?;
      if (value != null) {
        return createFVBFuture<DocumentSnapshot>(
            value.delete(), null, null, args.last);
      }
    }
    return FVBTest(DataType.future(DataType.fvbVoid), false);
  }),
  FVBFunction(
      'set',
      null,
      [
        FVBArgument(
          'data',
          dataType: fvbMapStringDynamic,
        )
      ],
      returnType: DataType.future(fvbDocumentSnapshotType),
      canReturnNull: false, dartCall: (args, self) {
    if (Processor.operationType != OperationType.checkOnly) {
      final value = self?.variables['_instance']?.value as DocumentReference?;
      if (value != null) {
        return createFVBFuture<void>(
            value.set(Map<String, dynamic>.from(args.first)),
            null,
            null,
            args.last);
      }
    }
    return FVBTest(DataType.future(DataType.fvbVoid), false);
  }),
  FVBFunction(
      'update',
      null,
      [
        FVBArgument(
          'data',
          dataType: fvbMapStringDynamic,
        )
      ],
      returnType: DataType.future(fvbDocumentSnapshotType),
      canReturnNull: false, dartCall: (args, self) {
    if (Processor.operationType != OperationType.checkOnly) {
      final value = self?.variables['_instance']?.value as DocumentReference?;
      if (value != null) {
        return createFVBFuture<void>(
            value.update(Map<String, dynamic>.from(args.first)),
            null,
            null,
            args.last);
      }
    }
    return FVBTest(DataType.future(DataType.fvbVoid), false);
  }),
  FVBFunction(
      'collection', null, [FVBArgument('path', type: FVBArgumentType.placed)],
      returnType: collectionRefType,
      canReturnNull: true, dartCall: (args, instance) {
    if (Processor.operationType != OperationType.checkOnly) {
      final FirebaseFirestore? fireStore =
          (instance as FVBInstance).variables['_instance']?.value;
      if (fireStore != null) {
        return firebaseFirestoreCollection
            .createInstance(args.last, [fireStore.collection(args[0])]);
      } else {
        (args.last as Processor).enableError(
            'Couldn\'t find FirebaseInstance, make sure it is connected from Project -> Firebase Connect.');
      }
    }
    return FVBTest(collectionRefType, true);
  })
]);
final FVBClass fvbDocumentSnapshot = FVBClass.create('DocumentSnapshot', vars: {
  '_instance': () =>
      FVBVariable('_instance', DataType.dart('DocumentSnapshot')),
  'exists': () =>
      FVBVariable('exists', DataType.fvbBool, getCall: (data, processor) {
        if (Processor.operationType != OperationType.checkOnly) {
          return (processor.variables['_instance']?.value as DocumentSnapshot)
              .exists;
        }
        return const FVBTest(DataType.fvbBool, false);
      }),
  'id': () => FVBVariable('id', DataType.string, getCall: (data, processor) {
        if (Processor.operationType != OperationType.checkOnly) {
          return (processor.variables['_instance']?.value as DocumentSnapshot)
              .id;
        }
        return const FVBTest(DataType.string, true);
      }),
}, funs: [
  FVBFunction('DocumentSnapshot', '', [FVBArgument('this._instance')]),
  FVBFunction('data', null, [],
      returnType: fvbMapStringDynamic,
      canReturnNull: true, dartCall: (args, self) {
    if (Processor.operationType != OperationType.checkOnly) {
      return (self?.variables['_instance']?.value as DocumentSnapshot).data();
    }
    return FVBTest(fvbMapStringDynamic, true);
  }),
]);
final FVBClass firebaseFirestoreCollection =
    FVBClass.create('CollectionReference', vars: {
  '_instance': () =>
      FVBVariable('_instance', DataType.dart('CollectionReference'))
}, funs: [
  FVBFunction('CollectionReference', '', [FVBArgument('this._instance')]),
  FVBFunction(
      'doc', null, [FVBArgument('id', type: FVBArgumentType.optionalPlaced)],
      returnType: docType, canReturnNull: true, dartCall: (args, instance) {
    if (Processor.operationType != OperationType.checkOnly) {
      final CollectionReference? reference =
          (instance as FVBInstance).variables['_instance']?.value;
      if (reference != null) {
        return firebaseFirestoreDoc
            .createInstance(args.last, [reference.doc(args[0])]);
      } else {
        (args.last as Processor).enableError(
            'Couldn\'t find collection, make sure path is correct!');
      }
    }
    return FVBTest(docType, true);
  }),
  FVBFunction('get', null, [],
      returnType: DataType.future(fvbQuerySnapshotType),
      canReturnNull: false, dartCall: (args, self) {
    if (Processor.operationType != OperationType.checkOnly) {
      final value = self?.variables['_instance']?.value as CollectionReference?;
      if (value != null) {
        return createFVBFuture<QuerySnapshot>(value.get(), 'QuerySnapshot',
            (data) {
          return fvbQuerySnapshot.createInstance(args.last, [data]);
        }, args.last, instanceName: '_instance');
      }
    }
    return FVBTest(DataType.future(fvbQuerySnapshotType), false);
  }),
]);

final FVBClass firestoreClass = FVBClass.create('FirebaseFirestore', vars: {
  '_instance': () =>
      FVBVariable('_instance', DataType.dart('FirebaseFirestore'))
}, funs: [
  FVBFunction('FirebaseFirestore', '', [FVBArgument('this._instance')]),
  FVBFunction(
      'collection', null, [FVBArgument('path', type: FVBArgumentType.placed)],
      returnType: collectionRefType,
      canReturnNull: true, dartCall: (args, instance) {
    if (Processor.operationType != OperationType.checkOnly) {
      final FirebaseFirestore? firestore =
          (instance as FVBInstance).variables['_instance']?.value;
      if (firestore != null) {
        return firebaseFirestoreCollection
            .createInstance(args.last, [firestore.collection(args[0])]);
      } else {
        (args.last as Processor).enableError(
            'Couldn\'t find FirebaseInstance, make sure it is connected from Project -> Firebase Connect');
      }
    }
    return FVBTest(collectionRefType, true);
  })
], staticVars: [
  FVBVariable('instance', fireStoreType, getCall: (data, processor) {
    if (Processor.operationType != OperationType.checkOnly) {
      return firestoreClass.createInstance(
          processor, [FirebaseFirestore.instanceFor(app: dataBridge.app!)]);
    }
    return FVBTest(fireStoreType, false);
  }),
]);

final pageViewClass = FVBClass('PageView', fvbFunctions: {
  'setPage': FVBFunction('setPage', null, [FVBArgument('page')]),
}, fvbVariables: {
  'controller': () => FVBVariable(
        'controller',
        DataType.fvbInstance('PageController'),
      ),
});
final tabBarClass = FVBClass('TabBar', fvbFunctions: {}, fvbVariables: {
  'controller': () => FVBVariable(
        'controller',
        DataType.fvbInstance('TabController'),
      ),
});
final formClass = FVBClass(
  'Form',
  fvbFunctions: {
    'validate': FVBFunction(
      'validate',
      null,
      [],
      returnType: DataType.fvbBool,
      canReturnNull: false,
    )
  },
  fvbVariables: {},
);
final fvbApiResponse = FVBClass.create('ApiResponse', vars: {
  'status': () => FVBVariable('status', DataType.fvbInt, isFinal: true),
  'statusMessage': () =>
      FVBVariable('statusMessage', DataType.string, isFinal: true),
  'header': () => FVBVariable(
      'header', DataType.map([DataType.string, DataType.list(DataType.string)]),
      nullable: true, isFinal: true),
  'body': () =>
      FVBVariable('body', DataType.string, nullable: true, isFinal: true),
  'bodyMap': () => FVBVariable('bodyMap', fvbMapStringDynamic,
      nullable: true, isFinal: true),
  'bodyList': () => FVBVariable('bodyList', DataType.list(DataType.fvbDynamic),
      nullable: true, isFinal: true),
  'bodyModel': () => FVBVariable('bodyModel', DataType.fvbDynamic,
      nullable: true, isFinal: true),
  'extra': () =>
      FVBVariable('extra', fvbMapStringDynamic, nullable: true, isFinal: true),

  'error': () =>
      FVBVariable('error', DataType.string, nullable: true, isFinal: true),

  'message': () =>
      FVBVariable('message', DataType.string, nullable: true, isFinal: true),
  // 'body': () => FVBVariable(
  //   'body',
  //   DataType.map([DataType.string, DataType.fvbDynamic]),
  // ),
}, funs: [
  FVBFunction('ApiResponse', '', [
    FVBArgument('this.status'),
    FVBArgument('this.statusMessage'),
    FVBArgument('this.header', nullable: true),
    FVBArgument('this.body', nullable: true),
    FVBArgument('this.bodyMap', nullable: true),
    FVBArgument('this.bodyList', nullable: true),
    FVBArgument('this.bodyModel', nullable: true),
    FVBArgument('this.extra', nullable: true),
    FVBArgument('this.error', nullable: true),
    FVBArgument('this.message', nullable: true),
  ])
]);

T handle<T>(dynamic value, Processor processor) {
  if (value is FVBTest) {
    return value.testValue(processor);
  }
  return value as T;
}

class FVBModuleClasses {
  static final fvbColorClass = FVBClass.create('Color',
      vars: {
        'value': () => FVBVariable('value', DataType.fvbInt),
      },
      funs: [
        FVBFunction('toString', null, [], dartCall: (args, ins) {
          if (Processor.operationType == OperationType.regular) {
            return 'Color(0x${(ins?.variables['value']?.value as int?)?.toRadixString(16)})';
          }
          return const FVBTest(DataType.string, false);
        }),
        FVBFunction('Color', '', [
          FVBArgument('this.value', type: FVBArgumentType.placed)
        ], dartCall: (arguments, instance) {
          if (Processor.operationType == OperationType.regular) {
            (arguments.last as Processor).variables['_dart'] = FVBVariable(
                '_dart', DataType.fvbDynamic,
                value:
                    Color(handle(arguments[0], arguments.last as Processor)));
          }
          return null;
        }),
        //withOpacity
        FVBFunction('withOpacity', null, [
          FVBArgument('opacity',
              dataType: DataType.fvbDouble, type: FVBArgumentType.placed)
        ], dartCall: (arguments, instance) {
          final processor = arguments.last as Processor;
          return fvbClasses['Color']!.createInstance(
            arguments.last,
            [
              (processor.variables['_dart']!.value as Color)
                  .withOpacity(
                      handle(arguments[0], arguments.last as Processor))
                  .value
            ],
          );
        }),
        //withAlpha
        FVBFunction('withAlpha', '', [
          FVBArgument('this.alpha', type: FVBArgumentType.placed)
        ], dartCall: (arguments, instance) {
          final processor = arguments.last as Processor;
          return fvbClasses['Color']!.createInstance(arguments.last, [
            (processor.variables['_dart']!.value as Color)
                .withAlpha(handle<int>(arguments[0], processor))
                .value
          ]);
        }),
      ],
      converter: ColorConverter());
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
  static final Map<String, FVBClass> fvbClasses = {
    'Size': FVBClass.create('Size', vars: {
      'width': () => FVBVariable('width', DataType.fvbDouble),
      'height': () => FVBVariable('height', DataType.fvbDouble),
    }, funs: [
      FVBFunction('Size', '', [
        FVBArgument('this.width', dataType: DataType.fvbDouble),
        FVBArgument('this.height', dataType: DataType.fvbDouble),
      ])
    ]),
    'Api': fvbApiClass,
    'BoxConstraints': FVBClass.create('BoxConstraints', vars: {
      'maxWidth': () =>
          FVBVariable('maxWidth', DataType.fvbDouble, getCall: (args, self) {
            if (Processor.operationType == OperationType.checkOnly) {
              return 0;
            }
            return (self.variables['_dart']?.value as BoxConstraints).maxWidth;
          }),
      'minWidth': () =>
          FVBVariable('minWidth', DataType.fvbDouble, getCall: (args, self) {
            if (Processor.operationType == OperationType.checkOnly) {
              return 0;
            }
            return (self.variables['_dart']?.value as BoxConstraints).minWidth;
          }),
      'maxHeight': () =>
          FVBVariable('maxHeight', DataType.fvbDouble, getCall: (args, self) {
            if (Processor.operationType == OperationType.checkOnly) {
              return 0;
            }
            return (self.variables['_dart']?.value as BoxConstraints).maxHeight;
          }),
      'minHeight': () =>
          FVBVariable('minHeight', DataType.fvbDouble, getCall: (args, self) {
            if (Processor.operationType == OperationType.checkOnly) {
              return 0;
            }
            return (self.variables['_dart']?.value as BoxConstraints).minHeight;
          })
    }, funs: [
      FVBFunction(
        'BoxConstraints',
        null,
        [
          FVBArgument('constraints', dataType: DataType.fvbDynamic),
        ],
        dartCall: (args, instance) =>
            (args.last as Processor).variables['_dart'] = FVBVariable(
          '_dart',
          DataType.fvbDynamic,
          value: handle(args[0], args.last),
        ),
      )
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
              (args.last as Processor).variables['_dart'] =
                  FVBVariable('_dart', DataType.fvbDynamic,
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
              (args.last as Processor).variables['_dart'] = FVBVariable(
            '_dart',
            DataType.fvbDynamic,
            value: Offset(handle(args[0], args.last as Processor),
                handle(args[1], args.last as Processor)),
          ),
        ),
      ],
      vars: {
        'dx': () => FVBVariable('dx', DataType.fvbDouble),
        'dy': () => FVBVariable('dy', DataType.fvbDouble),
      },
    ),
    'TextField': FVBClass('TextField', fvbFunctions: {
      'setText': FVBFunction('setText', null, [FVBArgument('text')]),
      'clear': FVBFunction('clear', '', []),
    }, fvbVariables: {
      'text': () => FVBVariable('text', DataType.string),
    }),
    'PageView': pageViewClass,
    'TabBar': tabBarClass,
    'PageController': FVBClass.create('PageController', vars: {
      '_dart': () => FVBVariable('_dart', DataType.fvbDynamic),
    }, funs: [
      FVBFunction(
          'jumpToPage', null, [FVBArgument('index', dataType: DataType.fvbInt)],
          dartCall: (args, instance) {
        if (Processor.operationType != OperationType.checkOnly) {
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
        if (Processor.operationType != OperationType.checkOnly) {
          (instance?.variables['_dart']?.value as PageController?)
              ?.animateToPage(
            args[0],
            duration: (args[1] as FVBInstance).toDart(),
            curve: handle<Curve>(args[2], args.last),
          );
        }
        // (args[])
      }),
    ]),
    'TabController': FVBClass.create('TabController', vars: {
      '_dart': () => FVBVariable('_dart', DataType.fvbDynamic),
      'index': () =>
          FVBVariable('index', DataType.fvbInt, getCall: (args, processor) {
            return (processor.variables['_dart']?.value as TabController?)
                ?.index;
          }, setCall: (processor, self, value) {
            (processor.variables['_dart']?.value as TabController?)?.index =
                value;
          }),
    }, funs: [
      FVBFunction('animateTo', null, [
        FVBArgument('value', dataType: DataType.fvbInt),
        FVBArgument('duration',
            type: FVBArgumentType.optionalNamed, nullable: false),
        FVBArgument('curve',
            type: FVBArgumentType.optionalNamed, nullable: false)
      ], dartCall: (args, instance) {
        if (Processor.operationType != OperationType.checkOnly) {
          (instance?.variables['_dart']?.value as TabController?)?.animateTo(
            args[0],
            duration: (args[1] as FVBInstance).toDart(),
            curve: handle<Curve>(args[2], args.last),
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
        if (Processor.operationType == OperationType.checkOnly) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          (args[0] as FVBFunction).execute(args.last, instance, [timeStamp]);
        });
      }),
    ]),
    'Future': FVBClass('Future', fvbFunctions: {
      'Future.delayed': FVBFunction('Future.delayed', '', [
        FVBArgument('duration', dataType: DataType.fvbInstance('Duration')),
        FVBArgument('computation',
            type: FVBArgumentType.optionalPlaced,
            dataType: DataType.fvbFunction,
            nullable: true)
      ], dartCall: (args, instance) {
        final processor = args.last as Processor;
        final fvbFuture = fvbClasses['Future']!.createInstance(processor, []);
        if (Processor.operationType == OperationType.checkOnly &&
            args.length > 1) {
          (args[1] as FVBFunction?)?.execute(processor, instance, []);
        } else {
          fvbFuture.variables['future']!.value = Future.delayed(
              (args[0] as FVBInstance).toDart(),
              args.length == 2 && args[1] != null
                  ? () async {
                      if (Processor.error || processor.finished) {
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
      }, isFactory: true),
      'then': FVBFunction('then', 'onValue=value;', [
        FVBArgument('value',
            dataType: DataType.generic('T'),
            type: FVBArgumentType.optionalPlaced)
      ]),
      'onError': FVBFunction('onError', 'onError=error;',
          [FVBArgument('error', type: FVBArgumentType.optionalPlaced)]),
    }, fvbVariables: {
      'value': () => FVBVariable('value', DataType.fvbDynamic),
      'future': () => FVBVariable('future', DataType.fvbDynamic),
      'onValue': () =>
          FVBVariable('onValue', DataType.fvbFunction, nullable: true),
      'onError': () =>
          FVBVariable('onError', DataType.fvbFunction, nullable: true),
    }, generics: [
      'T'
    ]),
    // 'FirebaseFirestore':FVBClass.create('FirebaseFirestore',staticVars: [
    //   FVBVariable('instance',getCall: (data,processor)=>),
    // ]
    // ),
    'SharedPreferences': FVBClass.create('SharedPreferences', funs: [
      FVBFunction('SharedPreferences.getInstance', null, [],
          dartCall: (arguments, instance) {
        final preferences = fvbClasses['SharedPreferences']!
            .createInstance(arguments.last as Processor, []);
        final fvbFuture = fvbClasses['Future']!.createInstance(
            arguments.last, [],
            parsedGenerics: [DataType.fvbInstance(preferences.fvbClass.name)]);
        fvbFuture.variables['future']!.value = Future<FVBInstance>(() async {
          final pref = await SharedPreferences.getInstance();
          preferences.variables['_pref']!.value = pref;
          fvbFuture.variables['value']!.value = preferences;
          (fvbFuture.variables['onValue']?.value as FVBFunction?)
              ?.execute(arguments.last as Processor, instance, [preferences]);
          return preferences;
        });

        return fvbFuture;
      }, isFactory: true),
      FVBFunction('setInt', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbInt),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          pref?.setInt(arguments[0] as String, arguments[1] as int);
        }
      }),
      FVBFunction('setString', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          pref?.setString(arguments[0] as String, arguments[1] as String);
        }
      }),
      FVBFunction('setBool', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbBool),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          pref?.setBool(arguments[0] as String, arguments[1] as bool);
        }
      }),
      FVBFunction('setDouble', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.fvbDouble),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          pref?.setDouble(arguments[0] as String, arguments[1] as double);
        }
      }),
      FVBFunction('setStringList', null, [
        FVBArgument('key', dataType: DataType.string),
        FVBArgument('value', dataType: DataType.list(DataType.string)),
      ], dartCall: (arguments, instance) {
        final processor = arguments[2] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          pref?.setStringList(
              arguments[0] as String, arguments[1] as List<String>);
        }
      }),
      FVBFunction('getInt', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          return pref?.getInt(arguments[0] as String);
        }
        return const FVBTest(DataType.fvbInt, false);
      }, returnType: DataType.fvbInt, canReturnNull: true),
      FVBFunction('getString', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          return pref?.getString(arguments[0] as String);
        }
        return const FVBTest(DataType.string, false);
      }, returnType: DataType.string, canReturnNull: true),
      FVBFunction('getBool', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          return pref?.getBool(arguments[0] as String);
        }
        return const FVBTest(DataType.fvbBool, false);
      }, returnType: DataType.fvbBool, canReturnNull: true),
      FVBFunction('getDouble', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          return pref?.getDouble(arguments[0] as String);
        }
        return const FVBTest(DataType.fvbDouble, false);
      }, returnType: DataType.fvbDouble, canReturnNull: true),
      FVBFunction('getStringList', null, [
        FVBArgument('key', dataType: DataType.string),
      ], dartCall: (arguments, instance) {
        final processor = arguments[1] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          return pref?.getStringList(arguments[0] as String);
        }
        return FVBTest(DataType.list(DataType.string), false);
      }, returnType: DataType.list(DataType.string), canReturnNull: true),
      FVBFunction(
          'containsKey',
          null,
          [
            FVBArgument('key', dataType: DataType.string),
          ],
          returnType: DataType.fvbBool, dartCall: (arguments, instance) {
        final processor = arguments[1] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          return pref!.containsKey(arguments[0] as String);
        }
        return const FVBTest(DataType.fvbBool, false);
      }),
      FVBFunction('clear', null, [],
          isAsync: true,
          returnType: DataType.future(), dartCall: (arguments, instance) {
        final processor = arguments[1] as Processor;
        final pref = processor.variables['_pref']?.value as SharedPreferences?;
        if (Processor.operationType != OperationType.checkOnly) {
          return pref!.clear();
        }
        return const FVBTest(DataType.fvbBool, false);
      }),
    ], vars: {
      '_pref': () => FVBVariable('_pref', DataType.fvbDynamic)
    }),
    'ApiResponse': fvbApiResponse,
    'Widget': widgetClass,
    'FVB': FVBClass.create('FVB', staticVars: [
      FVBVariable('vars', DataType.string, getCall: (args, process) {
        return process.variables.keys.toString();
      }),
      FVBVariable('localVars', DataType.string, getCall: (args, process) {
        return process.localVariables.keys.toString();
      }),
      FVBVariable('scope', DataType.string, getCall: (args, process) {
        return process.scopeName;
      }),
    ]),
    'FirebaseFirestore': firestoreClass,
    'DocumentReference': firebaseFirestoreDoc,
    'CollectionReference': firebaseFirestoreCollection,
    'DocumentSnapshot': fvbDocumentSnapshot,
    'QuerySnapshot': fvbQuerySnapshot,

    'App': FVBClass.create('App', library: 'common/app', staticVars: [
      FVBVariable(
        'pages',
        DataType.fvbInstance('Pages'),
        getCall: (args, process) {
          final Map<String, FVBVariable Function()> map = {};
          for (final screen in collection.project!.screens) {
            final key = StringOperation.toSnakeCase(screen.name);
            final camelCase =
                StringOperation.toCamelCase(screen.name, startWithLower: true);
            map[camelCase] =
                () => FVBVariable(camelCase, DataType.string, value: key);
          }
          return FVBClass.create('Pages', vars: map)
              .createInstance(process, []);
        },
      ),
      FVBVariable('widgets', DataType.fvbInstance('Widgets'),
          getCall: (args, process) {
        final Map<String, FVBVariable Function()> map = {};
        for (final screen in collection.project!.customComponents) {
          final key =
              StringOperation.toCamelCase(screen.name, startWithLower: true);
          final args = screen.argumentVariables
              .map((e) => e.toArg)
              .toList(growable: false);
          final fun1 = FVBFunction(key, null, args, dartCall: (args, ins) {
            final len = screen.componentClass.fvbVariables.length;
            return screen.componentClass.createInstance(
              process,
              args.length == len + 2
                  ? args.sublist(1, args.length - 1)
                  : args.sublist(0, args.length - 1),
            );
          }, returnType: DataType.widget);
          map[key] = () => FVBVariable(
              key,
              DataType.fvbFunctionOf(DataType.widget,
                  args.map((e) => e.dataType).toList(growable: false)),
              value: fun1);
        }
        return FVBClass.create('Widgets', vars: map)
            .createInstance(process, []);
      }, evaluate: true),
      FVBVariable('apis', DataType.fvbInstance('Api'),
          getCall: (args, process) {
        final Map<String, FVBVariable Function()> map = {};
        for (final e in collection.project!.apiModel.apis) {
          map[e.name] = (() => FVBVariable(e.name, DataType.fvbInstance('Api'),
                  getCall: (args, process) {
                return FVBClass.create('Api', funs: [
                  FVBFunction(
                      'fetch',
                      '',
                      e.processor.variables.entries
                          .map<FVBArgument>((entry) => FVBArgument(entry.key,
                              type: FVBArgumentType.optionalNamed,
                              dataType: entry.value.dataType,
                              defaultVal: entry.value.value))
                          .toList(growable: false),
                      returnType:
                          DataType.future(DataType.fvbInstance('ApiResponse')),
                      canReturnNull: true, dartCall: (args, instance) {
                    if (Processor.operationType == OperationType.checkOnly) {
                      return FVBTest(
                          DataType.future(DataType.fvbInstance('ApiResponse')),
                          true);
                    }
                    final bloc = sl<FVBApiBloc>();
                    return createFVBFuture<ApiResponseModel>(
                        bloc.callApi(args.last, e, args), 'ApiResponse',
                        (data) {
                      dynamic jsonData;
                      if (data.body != null) {
                        try {
                          jsonData = jsonDecode(data.body!);
                        } catch (e) {
                          if (kDebugMode) {
                            print('JSON ENCODE ERROR ${e.toString()}');
                          }
                        }
                      }
                      return fvbApiResponse.createInstance(args.last, [
                        data.status,
                        data.statusMessage,
                        data.headers,
                        data.body,
                        jsonData is! List ? jsonData : null,
                        jsonData is List ? jsonData : null,
                        e.convertToDart
                            ? CodeOperations.jsonToModel(jsonData, process,
                                '${StringOperation.capitalize(e.name)}Response')
                            : null,
                        data.extra,
                        data.error,
                        data.message
                      ]);
                    }, args.last);
                  })
                ]).createInstance(process, []);
              }));
        }
        return FVBClass.create('Api', vars: map).createInstance(process, []);
      }),
      FVBVariable(
        'firestore',
        DataType.fvbInstance('FirebaseFirestore'),
        getCall: (args, processor) {
          if (Processor.operationType != OperationType.checkOnly) {
            return firestoreClass.createInstance(processor,
                [FirebaseFirestore.instanceFor(app: dataBridge.app!)]);
          }
          return FVBTest(fireStoreType, false);
        },
      ),
    ], staticFuns: [
      FVBFunction('arguments', null, [Arguments.buildContext],
          returnType: DataType.list(null), dartCall: (args, self) {
        if (Processor.operationType == OperationType.checkOnly) {
          return [];
        }
        if (args[0] is! BuildContext) {
          (args[1] as Processor)
              .enableError('Invalid variable passed, require buildContext');
        }
        return ModalRoute.of(args[0])?.settings.arguments ?? [];
      }),
      FVBFunction(
          'pop',
          null,
          [
            Arguments.buildContext,
          ],
          returnType: DataType.fvbVoid, dartCall: (args, self) {
        if (Processor.operationType == OperationType.checkOnly) {
          return;
        }
        if (fvbNavigationBloc.model.dialog) {
          fvbNavigationBloc.model.dialog = false;
          fvbNavigationBloc.add(FvbNavigationChangedEvent());
        } else if (fvbNavigationBloc.model.bottomSheet) {
          fvbNavigationBloc.model.bottomSheet = false;
          fvbNavigationBloc.add(FvbNavigationChangedEvent());
        }
        navigationKey?.currentState?.pop();
      }),
      fvbFunPush,
      fvbFunShowSnackBar,
      fvbFunShowDialog,
      fvbFunShowAlertDialog,
      fvbFunShowBottomSheet,
      fvbFunShowDatePicker
    ]),
    'http': FVBClass(
      'http',
      fvbFunctions: {
        'get': FVBFunction('get', null, [FVBArgument('url')])
          ..dartCall = (arguments, instance) async {
            return (await http.get(arguments[0])).body;
          },
      },
      fvbVariables: {},
    ),

    /// Dart Class [Duration]
    'Duration': FVBClass('Duration',
        fvbFunctions: {
          'Duration': FVBFunction('Duration', '', [
            FVBArgument('this.microseconds',
                type: FVBArgumentType.optionalNamed,
                defaultVal: 0,
                dataType: DataType.fvbInt),
            FVBArgument('this.milliseconds',
                type: FVBArgumentType.optionalNamed,
                defaultVal: 0,
                dataType: DataType.fvbInt),
            FVBArgument('this.seconds',
                type: FVBArgumentType.optionalNamed,
                defaultVal: 0,
                dataType: DataType.fvbInt),
            FVBArgument('this.minutes',
                type: FVBArgumentType.optionalNamed,
                defaultVal: 0,
                dataType: DataType.fvbInt),
            FVBArgument('this.hours',
                type: FVBArgumentType.optionalNamed,
                defaultVal: 0,
                dataType: DataType.fvbInt),
            FVBArgument('this.days',
                type: FVBArgumentType.optionalNamed,
                defaultVal: 0,
                dataType: DataType.fvbInt),
          ], dartCall: (args, instance) {
            (args[args.length - 2] as FVBInstance).variables['_dart'] =
                FVBVariable(
                    '_dart', DataType.fvbDynamic,
                    value: fromInstanceToDuration(
                        (args[args.length - 2] as FVBInstance).variables));
            return null;
          }),
        },
        fvbVariables: {
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
    'Color': fvbColorClass,
    'Colors': FVBClass.create('Colors', staticVars: [
      FVBVariable(
        'black',
        fvbColor,
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.black.value]),
      ),
      FVBVariable(
        'transparent',
        fvbColor,
        getCall: (obj, processor) => fvbClasses['Color']!
            .createInstance(processor, [Colors.transparent.value]),
      ),
      FVBVariable(
        'red',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.red.value]),
      ),
      FVBVariable(
        'green',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.green.value]),
      ),
      FVBVariable(
        'blue',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.blue.value]),
      ),
      //blueaccent
      FVBVariable(
        'cyan',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.cyan.value]),
      ),
      FVBVariable(
        'teal',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.teal.value]),
      ),
      FVBVariable(
        'greenAccent',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.greenAccent.value]),
      ),
      //blueaccent
      FVBVariable(
        'blueAccent',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.blueAccent.value]),
      ),
      FVBVariable(
        'indigo',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.indigo.value]),
      ),

      FVBVariable(
        'lightGreen',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.lightGreen.value]),
      ),
      FVBVariable(
        'lime',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.lime.value]),
      ),
      FVBVariable(
        'yellow',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.yellow.value]),
      ),
      FVBVariable(
        'amber',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.amber.value]),
      ),
      FVBVariable(
        'orange',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.orange.value]),
      ),
      FVBVariable(
        'deepOrange',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.deepOrange.value]),
      ),
      FVBVariable(
        'brown',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.brown.value]),
      ),

      FVBVariable(
        'white',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.white.value]),
      ),
      FVBVariable(
        'grey',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.grey.value]),
      ),
      FVBVariable(
        'black87',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.black87.value]),
      ),
      FVBVariable(
        'black54',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.black54.value]),
      ),
      FVBVariable(
        'black45',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.black45.value]),
      ),
      FVBVariable(
        'black38',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.black38.value]),
      ),
      FVBVariable(
        'black26',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.black26.value]),
      ),
      FVBVariable(
        'black12',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.black12.value]),
      ),
      //purple
      FVBVariable(
        'purple',
        fvbColor,
        getCall: (obj, processor) =>
            fvbColorClass.createInstance(processor, [Colors.purple.value]),
      ),
      FVBVariable(
        'purpleAccent',
        fvbColor,
        getCall: (obj, processor) => fvbColorClass
            .createInstance(processor, [Colors.purpleAccent.value]),
      ),
    ]),

    /// canvasClass.fvbFunctions['drawPoint']!.dartCall = (arguments) {
    /// Paint()..color = Colors.red);
    /// canvas.drawRect(Rect.fromPoints(Offset(0, 0), Offset(100, 100)),
    ///
    /// };
    ///
    /// canvasClass.fvbFunctions['drawRect']!.dartCall = (arguments) {
    /// };
    'Canvas': FVBClass.create('Canvas', funs: [
      FVBFunction('Canvas', '', [FVBArgument('this._self')]),
      FVBFunction('drawPoint', null, []),
      FVBFunction('drawRect', null, [
        FVBArgument('rect', dataType: DataType.fvbInstance('Rect')),
        FVBArgument('paint', dataType: DataType.fvbInstance('Paint')),
      ], dartCall: (arguments, instance) {
        final rect = (arguments[0] as FVBInstance?)?.toDart();
        final paint = (arguments[1] as FVBInstance?)?.toDart();
        if (Processor.operationType == OperationType.regular) {
          ((arguments[2] as Processor).variables['_self']!.value as Canvas)
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
        if (Processor.operationType == OperationType.regular) {
          ((arguments[3] as Processor).variables['_self']!.value as Canvas)
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
        if (Processor.operationType == OperationType.regular) {
          ((arguments[3] as Processor).variables['_self']!.value as Canvas)
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
        if (Processor.operationType == OperationType.regular) {
          ((arguments.last as Processor).variables['_self']!.value as Canvas)
              .drawPoints(mode, points, paint);
        }
      }),
    ], vars: {
      '_self': () => FVBVariable('_self', DataType.fvbDynamic),
    }),
    'Timer': FVBClass('Timer',
        fvbFunctions: {
          'Timer': FVBFunction(
              'Timer', '', [FVBArgument('duration'), FVBArgument('callback')]),
          'cancel': FVBFunction('cancel', '', []),
        },
        fvbVariables: {},
        fvbStaticFunctions: {
          'periodic': FVBFunction('periodic', null,
              [FVBArgument('duration'), FVBArgument('callback')])
            ..dartCall = (arguments, instance) {
              final timerInstance = fvbClasses['Timer']!
                  .createInstance(arguments[2], arguments.sublist(0, 2));

              if (Processor.operationType == OperationType.checkOnly) {
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
                  if ((arguments[2] as Processor).finished || Processor.error) {
                    timer.cancel();
                    return;
                  }
                  (arguments[1] as FVBFunction)
                      .execute(arguments[2], instance, [timerInstance]);
                });
                Processor.timers.add(timer);
                timerInstance.fvbClass.fvbFunctions['cancel']!.dartCall =
                    (args, instance) {
                  timer.cancel();
                  Processor.timers.remove(timer);
                };
              }

              return timerInstance;
            },
        },
        parent: null),
    'int': FVBDartOperations.intOperations,
    'double': FVBDartOperations.doubleOperations,
    'num': FVBDartOperations.numOperations,
    'String': FVBDartOperations.stringOperations,
    'List': FVBDartOperations.listOperation,
    'Iterable': FVBDartOperations.iterableOperation,
    'Map': FVBDartOperations.mapOperation,
    'MapEntry': FVBDartOperations.mapEntryOperation,
    'Timestamp': FVBClass.create('Timestamp', vars: {
      '_dart': () => FVBVariable('_dart', DataType.dart('Timestamp'))
    }, funs: [
      FVBFunction('Timestamp', '',
          [FVBArgument('this._dart', type: FVBArgumentType.placed)]),
    ], staticFuns: [
      FVBFunction(
        'now',
        null,
        [],
        dartCall: (args, self) {
          return Timestamp.now();
        },
      ),
      FVBFunction(
        'fromDate',
        null,
        [FVBArgument('date', dataType: DataType.dateTime)],
        dartCall: (args, self) {
          if (Processor.operationType == OperationType.checkOnly) {
            return FVBTest(DataType.fvbInstance('Timestamp'), false);
          }
          return Timestamp.fromDate((args[0] as FVBInstance).toDart());
        },
      )
    ]),
    'DateTime': FVBClass('DateTime', fvbFunctions: {
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
        instance.variables['_dart']?.value = dateTime;
        return dateTime;
      }),
      'DateTime._dart': FVBFunction(
        'DateTime._dart',
        '',
        [
          FVBArgument(
            'this._dart',
            type: FVBArgumentType.placed,
          ),
        ],
      ),
      'toLocal': FVBFunction('toLocal', null, [], dartCall: (args, instance) {
        return fromDateTimeToInstance(
            ((args.last as Processor).variables['_dart']!.value as DateTime)
                .toLocal(),
            args.last);
      }),
      'toUtc': FVBFunction('toUtc', null, [], dartCall: (args, instance) {
        return fromDateTimeToInstance(
            ((args.last as Processor).variables['_dart']!.value as DateTime)
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
        return ((args.last as Processor).variables['_dart']!.value as DateTime)
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
        return ((args.last as Processor).variables['_dart']!.value as DateTime)
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
        return ((args.last as Processor).variables['_dart']!.value as DateTime)
            .difference(
                (args[0] as FVBInstance).variables['_dart']!.value as DateTime);
      }),
      'toString': FVBFunction('toString', null, [], dartCall: (args, instance) {
        final processor = args.last as Processor;
        return (processor.variables['_dart']?.value as DateTime).toString();
      }),
      'add': FVBFunction('add', null, [
        FVBArgument(
          'duration',
          type: FVBArgumentType.placed,
          dataType: DataType.fvbInstance('Duration'),
        ),
      ], dartCall: (args, instance) {
        final processor = args.last as Processor;
        return fromDateTimeToInstance(
            (processor.variables['_dart']!.value as DateTime)
                .add((args[0] as FVBInstance).variables['_dart']!.value),
            processor);
      }),
    }, fvbVariables: {
      'year': () => FVBVariable('year', DataType.fvbInt),
      'month': () => FVBVariable('month', DataType.fvbInt),
      'day': () => FVBVariable('day', DataType.fvbInt),
      'hour': () => FVBVariable('hour', DataType.fvbInt),
      'minute': () => FVBVariable('minute', DataType.fvbInt),
      'second': () => FVBVariable('second', DataType.fvbInt),
      'millisecond': () => FVBVariable('millisecond', DataType.fvbInt),
      'microsecond': () => FVBVariable('microsecond', DataType.fvbInt),
      '_dart': () => FVBVariable('_dart', DataType.dart('DateTime')),
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
    'DateFormat': FVBClass('DateFormat', fvbFunctions: {
      'DateFormat': FVBFunction('DateFormat', '', [
        FVBArgument('this.pattern',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return null;
        }
        (args[args.length - 2] as FVBInstance).variables['_dart'] = FVBVariable(
            '_dart', DataType.fvbDynamic,
            value: DateFormat(handle<String>(args[0], args.last)));
        return null;
      }),
      'format': FVBFunction('format', null, [
        FVBArgument('date',
            type: FVBArgumentType.placed,
            dataType: DataType.fvbInstance('DateTime')),
      ], dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return '';
        }
        final instance = (args.last as Processor);
        final dateFormat = instance.variables['_dart']!.value as DateFormat;
        return dateFormat
            .format((args[0] as FVBInstance).variables['_dart']!.value);
      }),
      'parse': FVBFunction('parse', null, [
        FVBArgument('string',
            type: FVBArgumentType.placed, dataType: DataType.string),
      ], dartCall: (args, instance) {
        if (Processor.operationType == OperationType.checkOnly) {
          return fromDateTimeToInstance(DateTime(0), (args.last as Processor));
        }
        final instance = (args.last as Processor);
        final dateFormat = instance.variables['_dart']!.value as DateFormat;
        return fromDateTimeToInstance(
            dateFormat.parse(handle<String>(args[0], instance)), instance);
      }),
    }, fvbVariables: {
      'pattern': () => FVBVariable('pattern', DataType.string),
    }),
  };

  FVBModuleClasses() {
    // Rect offset = Rect.fromPoints(a, b);
  }

  static FVBInstance fromDateTimeToInstance(
      DateTime dateTime, Processor processor) {
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
      ..variables['_dart']?.value = dateTime;
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
      days: variables['days']!.value ?? 0,
      hours: variables['hours']!.value ?? 0,
      minutes: variables['minutes']!.value ?? 0,
      seconds: variables['seconds']!.value ?? 0,
      milliseconds: variables['milliseconds']!.value ?? 0,
      microseconds: variables['microseconds']!.value ?? 0,
    );
  }
}

FVBInstance createFVBFuture<T>(Future future, String? name,
    FVBInstance? Function(T)? instance, Processor processor,
    {String instanceName = '_dart'}) {
  final fvbFuture = FVBModuleClasses.fvbClasses['Future']!.createInstance(
      processor, [],
      parsedGenerics:
          name != null ? [DataType.fvbInstance(name)] : [DataType.fvbVoid]);

  final fvbExecution = Future(() async {
    final eval = await future;
    if (instance != null) {
      final value = instance(eval);
      if (value?.variables.containsKey(instanceName) ?? false) {
        value?.variables[instanceName]?.value = eval;
      } else {
        value?.variables[instanceName] =
            FVBVariable(instanceName, DataType.fvbDynamic, value: eval);
      }
      return value;
    }
  });
  fvbFuture.variables['future']!.value = fvbExecution;
  fvbExecution.then((value) {
    fvbFuture.variables['value']!.value = value;
    (fvbFuture.variables['onValue']?.value as FVBFunction?)
        ?.execute(processor, null, [value]);
  }).onError((error, stackTrace) {
    (fvbFuture.variables['onError']?.value as FVBFunction?)
        ?.execute(processor, null, [error, stackTrace]);
  });
  return fvbFuture;
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
    final v = instance.variables['value']!.value;
    return Color(v is int ? v : 0);
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
