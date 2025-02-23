import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/bloc/navigation/fvb_navigation_bloc.dart';
import 'package:flutter_builder/common/converter/string_operation.dart';
import 'package:flutter_builder/common/material_alert.dart';
import 'package:flutter_builder/constant/string_constant.dart';
import 'package:flutter_builder/cubit/component_creation/component_creation_cubit.dart';
import 'package:flutter_builder/cubit/stack_action/stack_action_cubit.dart';
import 'package:flutter_builder/injector.dart';
import 'package:flutter_builder/models/project_model.dart';
import 'package:flutter_builder/ui/navigation/animated_dialog.dart';
import 'package:get/get_utils/get_utils.dart';

import 'argument_list.dart';
import 'code_processor.dart';
import 'fvb_class.dart';
import 'fvb_classes.dart';
import 'fvb_function_variables.dart';

final fvbFunPush = FVBFunction(
    'push',
    null,
    [
      Arguments.buildContext,
      FVBArgument('screen', dataType: DataType.string),
      FVBArgument('arguments',
          dataType: DataType.fvbDynamic, type: FVBArgumentType.optionalPlaced),
    ],
    returnType: DataType.fvbVoid, dartCall: (args, self) {
  if (Processor.operationType == OperationType.checkOnly) {
    return;
  }
  final Screen? screen = collection.project!.screens.firstWhereOrNull(
      (screen) =>
          StringOperation.toSnakeCase(screen.name) == args[args.length - 3]);
  Widget? widget;
  navigationKey?.currentState?.push(
    MaterialPageRoute(
      builder: (context) => widget != null
          ? widget!
          : widget = screen?.build(context) ?? const Offstage(),
      settings: RouteSettings(arguments: args[args.length - 2]),
    ),
  );
});
final fvbFunShowSnackBar = FVBFunction(
    'showSnackbar',
    null,
    [
      Arguments.buildContext,
      FVBArgument(
        'content',
        dataType: DataType.string,
      ),
      FVBArgument(
        'duration',
        dataType: DataType.fvbInstance('Duration'),
      ),
    ],
    returnType: DataType.fvbVoid, dartCall: (args, self) {
  if (Processor.operationType == OperationType.checkOnly) {
    return;
  }
  args.last.consoleCallback.call('api:snackbar', arguments: [
    args[0],
    args[1],
    (args[2] as FVBInstance).toDart(),
  ]);
});
final fvbFunShowBottomSheet = FVBFunction(
    'showBottomSheet',
    null,
    [
      Arguments.buildContext,
      FVBArgument(
        'component',
        dataType: DataType.widget,
      ),
      FVBArgument(
        'backgroundColor',
        dataType: fvbColor,
        nullable: true,
        type: FVBArgumentType.optionalNamed,
      ),
      FVBArgument(
        'enableDrag',
        dataType: DataType.fvbBool,
        nullable: true,
        type: FVBArgumentType.optionalNamed,
      ),
    ],
    returnType: DataType.future(DataType.fvbDynamic), dartCall: (args, self) {
  if (Processor.operationType == OperationType.checkOnly) {
    return;
  }
  final comp = collection.project!.customComponents.firstWhereOrNull(
      (element) => element.componentClass == (args[1] as FVBInstance).fvbClass);
  if (comp != null) {
    final bloc = sl<FvbNavigationBloc>();
    bloc.model.bottomSheet = true;
    bloc.model.bottomComp = comp;
    bloc.add(FvbNavigationChangedEvent());
    bloc.persistentBottomSheetController =
        (deviceScaffoldMessenger!.currentState as ScaffoldState?)
            ?.showBottomSheet(
      (_) => BlocBuilder<CreationCubit, CreationState>(
        builder: (context, state) => comp.build(context),
      ),
      backgroundColor: (args[2] as FVBInstance?)?.toDart(),
      enableDrag: args[3],
    );
  } else {
    (args.last as Processor).enableError(
        'Custom Widget ${(args[1] as FVBInstance).fvbClass.name} not found!!');
  }
});
final fvbFunShowDialog = FVBFunction(
    'dialog',
    null,
    [
      Arguments.buildContext,
      FVBArgument(
        'component',
        dataType: DataType.widget,
      ),
      FVBArgument('barrierColor',
          type: FVBArgumentType.optionalNamed,
          dataType: fvbColor,
          nullable: true),
      FVBArgument('barrierDismissible',
          type: FVBArgumentType.optionalNamed,
          dataType: DataType.fvbBool,
          nullable: true),
    ],
    returnType: DataType.fvbVoid, dartCall: (args, self) {
  if (Processor.operationType == OperationType.checkOnly) {
    // final bloc = sl<FvbNavigationBloc>();
    // bloc.model.dialog = true;
    // bloc.model.dialogComp = comp;
    // bloc.add(FvbNavigationChangedEvent());

    return;
  }
  final comp = collection.project!.customComponents.firstWhereOrNull(
      (element) => element.componentClass == (args[1] as FVBInstance).fvbClass);
  if (comp != null) {
    final context = (args[0] as BuildContext);
    //   bool barrierDismissible = ,
    //       Color? barrierColor =,
    // String? barrierLabel,
    // bool useSafeArea = true,
    // bool useRootNavigator = true,
    sl<StackActionCubit>().stackOperation(StackOperation.dialog, screen: comp);

    navigationKey?.currentState?.push(DialogRoute(
      context: context,

      ///TODO(UpdateDialog):
      builder: (_) => BlocBuilder<CreationCubit, CreationState>(
        builder: (context, state) => Center(child: comp.build(context)),
      ),
      barrierColor: args[2]?.toDart() ?? Colors.black54,
      barrierDismissible: args[3]?.toDart() ?? true,
      // barrierLabel: barrierLabel,
      useSafeArea: true,
      settings: null,
    ));
    // (args[0] as BuildContext)
    //     .read<StackActionCubit>()
    //     .showCustomSimpleDialog(
    //         ShowCustomDialogInStackAction(comp: comp));
  } else {
    (args.last as Processor).enableError(
        'Custom Widget ${(args[1] as FVBInstance).fvbClass.name} not found!!');
  }
  // showDialog(
  //     context: args[0],
  //     builder: (_) {
  //       return RuntimeProvider(
  //           runtimeMode: RuntimeProvider.of(args[0]),
  //           child:
  //                   ?.build(args[0]) ??
  //               Offstage());
  //     });
});
final fvbFunShowDatePicker = FVBFunction(
    'showDatePicker',
    null,
    [
      Arguments.buildContext,
      FVBArgument(
        'initialDate',
        dataType: DataType.dateTime,
        nullable: false,
        type: FVBArgumentType.optionalNamed,
      ),
      FVBArgument(
        'firstDate',
        dataType: DataType.dateTime,
        nullable: false,
        type: FVBArgumentType.optionalNamed,
      ),
      FVBArgument(
        'lastDate',
        dataType: DataType.dateTime,
        nullable: false,
        type: FVBArgumentType.optionalNamed,
      ),
    ],
    returnType: DataType.future(DataType.dateTime), dartCall: (args, self) {
  if (navigationKey?.currentContext == null ||
      Processor.operationType == OperationType.checkOnly) {
    return FVBTest(DataType.future(DataType.dateTime), false);
  }

  return createFVBFuture<DateTime?>(
      showDatePicker(
        context: navigationKey!.currentContext!,
        useRootNavigator: false,
        initialDate: (args[1] as FVBInstance).toDart(),
        firstDate: (args[2] as FVBInstance).toDart(),
        lastDate: (args[3] as FVBInstance).toDart(),
      ),
      'DateTime',
      (p0) => p0 != null
          ? FVBModuleClasses.fvbClasses['DateTime']?.createInstance(
              args.last, [p0],
              constructorName: 'DateTime._dart')
          : null,
      args.last);
});

final fvbFunShowAlertDialog = FVBFunction(
    'showAlertDialog',
    null,
    [
      Arguments.buildContext,
      FVBArgument(
        'title',
        dataType: DataType.string,
        type: FVBArgumentType.optionalNamed,
        nullable: false,
      ),
      FVBArgument(
        'subtitle',
        dataType: DataType.string,
        type: FVBArgumentType.optionalNamed,
        nullable: false,
      ),
      FVBArgument(
        'positive',
        dataType: DataType.string,
        type: FVBArgumentType.optionalNamed,
        nullable: false,
      ),
      FVBArgument(
        'negative',
        dataType: DataType.string,
        type: FVBArgumentType.optionalNamed,
        nullable: true,
      ),
      FVBArgument(
        'positiveCallback',
        dataType: DataType.fvbFunctionOf(DataType.fvbVoid, []),
        type: FVBArgumentType.optionalNamed,
        nullable: false,
      ),
      FVBArgument(
        'negativeCallback',
        dataType: DataType.fvbFunctionOf(DataType.fvbVoid, []),
        type: FVBArgumentType.optionalNamed,
        nullable: true,
      ),
      FVBArgument('dismissible',
          type: FVBArgumentType.optionalNamed,
          dataType: DataType.fvbBool,
          defaultVal: false),
    ],
    returnType: DataType.fvbVoid, dartCall: (args, self) {
  if (Processor.operationType == OperationType.checkOnly) {
    return;
  }
  final context = (args[0] as BuildContext);
  //   bool barrierDismissible = ,
  //       Color? barrierColor =,
  // String? barrierLabel,
  // bool useSafeArea = true,
  // bool useRootNavigator = true,
  final bloc = sl<FvbNavigationBloc>();
  bloc.model.dialog = true;
  bloc.add(FvbNavigationChangedEvent());
  AnimatedDialog.show(
    context,
    MaterialAlertDialog(
      title: args[1],
      subtitle: args[2],
      positiveButtonText: args[3],
      negativeButtonText: args[4],
      onPositiveTap: args[5] != null
          ? () => (args[5] as FVBFunction).execute(args.last, self, [])
          : null,
      onNegativeTap: args[6] != null
          ? () => (args[6] as FVBFunction).execute(args.last, self, [])
          : null,
    ),
    key: args[1],
    barrierDismissible: args[7],
    navigator: navigationKey?.currentState,
  );
});
