import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:get/get.dart';

import '../bloc/error/error_bloc.dart';
import '../bloc/navigation/fvb_navigation_bloc.dart';
import '../bloc/state_management/state_management_bloc.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../constant/string_constant.dart';
import '../cubit/stack_action/stack_action_cubit.dart';
import '../injector.dart';
import '../main.dart';
import '../models/project_model.dart';
import '../runtime_provider.dart';
import '../ui/fvb_code_editor.dart';
import '../ui/navigation/animated_dialog.dart';
import '../widgets/textfield/app_textfield.dart';
import 'extension_util.dart';
import 'material_alert.dart';
import 'web/io_lib.dart';

Future<void> showConfirmDialog({
  required String title,
  required String subtitle,
  required BuildContext context,
  required String positive,
  bool dismissible = true,
  String? negative,
  VoidCallback? onPositiveTap,
  VoidCallback? onNegativeTap,
}) async {
  await AnimatedDialog.show(
      context,
      MaterialAlertDialog(
        title: title,
        subtitle: subtitle,
        positiveButtonText: positive,
        negativeButtonText: negative,
        onPositiveTap: onPositiveTap,
        onNegativeTap: onNegativeTap,
      ),
      key: title,
      barrierDismissible: dismissible,
      rootNavigator: true);
}

void showEnterInfoDialog(BuildContext context, String title,
    {String positive = 'ok',
    String? initialValue,
    ValueChanged<String>? onPositive,
    String? negative = 'cancel',
    String? hint,
    VoidCallback? onNegative,
    FormFieldValidator? validator,
    bool multipleLines = false}) {
  final TextEditingController controller =
      TextEditingController(text: initialValue);
  final focusNode = FocusNode();
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    focusNode.requestFocus();
  });
  AnimatedDialog.show(
      context,
      AlertDialog(
        contentPadding: const EdgeInsets.all(15),
        elevation: 0,
        content: SizedBox(
          width: 400,
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFontStyle.titleStyle(),
                ),
                15.hBox,
                AppTextField(
                  hintText: hint,
                  validator: validator,
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: multipleLines ? 5 : null,
                  fontColor: ColorAssets.color222222,
                  fontWeight: FontWeight.w600,
                ),
                15.hBox,
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(builder: (context) {
                        return TextButton(
                          onPressed: () {
                            if (validator == null ||
                                Form.of(context).validate()) {
                              AnimatedDialog.hide(context);
                              onPositive?.call(controller.text);
                            }
                          },
                          child: Text(positive.toUpperCase()),
                        );
                      }),
                      if (negative != null) ...[
                        15.wBox,
                        TextButton(
                          onPressed: () {
                            AnimatedDialog.hide(context);
                            onNegative?.call();
                          },
                          child: Text(negative.toUpperCase()),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true);
}

void showPopupText(BuildContext context, final String message,
    {bool error = false, bool long = true}) async {
  final point =
      (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: point.dx,
      top: point.dy,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - point.dx - 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: ColorAssets.darkerGrey,
                borderRadius: BorderRadius.circular(10)),
            child: Text(
              message,
              style: AppFontStyle.lato(14,
                  color: Colors.white, fontWeight: FontWeight.w400),
            ),
          ).animate().scale().show(),
        ),
      ),
    ),
  );
  Overlay.of(context).insert(
    entry,
  );
  Future.delayed(Duration(milliseconds: long ? 3000 : 1500), () {
    entry.remove();
  });
}

void showToast(final String message, {bool error = false}) async {
  if (Platform.isMacOS || Platform.isWindows) {
    Get.showSnackbar(
      GetSnackBar(
        messageText: Text(
          message,
          textAlign: TextAlign.center,
          style: AppFontStyle.lato(16, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 300),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
    );
  } else {
    showConfirmDialog(
        title: error ? 'Error' : 'Alert',
        subtitle: message,
        context: rootNavigator.currentContext!,
        positive: 'ok');
    // await Fluttertoast.showToast(msg: message, timeInSecForIosWeb: 9, webBgColor: error ? '#ff0000' : '#00ff00');
  }
}

bool isKeyboardOpen(BuildContext context) {
  return MediaQuery.of(context).viewInsets.bottom > 0;
}

Future<dynamic> showModelDialog(BuildContext context, Widget builder) async {
  return await showDialog(context: context, builder: (_) => builder);
}

bool _dialogVisible = false;

Future<void> showAlertDialog(
  BuildContext context,
  String title,
  String subtitle, {
  String? positiveButton,
  String? negativeButton,
  VoidCallback? onPositiveButtonClick,
  VoidCallback? onNegativeButtonClick,
  bool dismissible = true,
}) async {
  if (_dialogVisible) {
    Navigator.pop(context);
  }
  _dialogVisible = true;
  await showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (_) {
        return MaterialAlertDialog(
          title: title,
          subtitle: subtitle,
          positiveButtonText: positiveButton ?? '',
          negativeButtonText: negativeButton ?? '',
          onPositiveTap: onPositiveButtonClick,
          onNegativeTap: onNegativeButtonClick,
        );
      });
  _dialogVisible = false;
}

final eventBloc = sl<EventLogBloc>();

void doAPIOperation(String message,
    {required StackActionCubit stackActionCubit,
    required StateManagementBloc stateManagementBloc,
    required List<dynamic>? arguments}) {
  if (message.startsWith('print:')) {
    eventBloc.add(ConsoleUpdatedEvent(
        ConsoleMessage(message.substring(6), ConsoleMessageType.info)));
  } else if (message.startsWith('api:')) {
    if (Processor.operationType == OperationType.checkOnly) {
      return;
    }
    final value = message.replaceAll('api:', '');
    final split = value.split('|');
    final action = split[0];
    if (split.length > 1) {
      sl<EventLogBloc>().add(ConsoleUpdatedEvent(
          ConsoleMessage('$action ${split[1]}', ConsoleMessageType.event)));
    }
    switch (action) {
      case 'snackbar':
        ScaffoldMessenger.maybeOf(arguments![0] as BuildContext)!
            .showSnackBar(SnackBar(
          content: Text(
            arguments[1],
            style: AppFontStyle.lato(14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          // backgroundColor: Colors.grey,
          duration: arguments[2],
        ));
        break;
      case 'newpage':
        final Screen? screen = collection.project!.screens
            .firstWhereOrNull((screen) => screen.name == split[1]);
        if (screen != null) {
          stackActionCubit.stackOperation(StackOperation.push, screen: screen);
        }
        navigationKey?.currentState?.push(
          MaterialPageRoute(
            builder: (context) => screen?.build(context) ?? const Offstage(),
            settings: RouteSettings(arguments: arguments),
          ),
        );
        break;
      case 'replacepage':
        final Screen? screen = collection.project!.screens
            .firstWhereOrNull((screen) => screen.name == split[1]);
        if (screen != null) {
          stackActionCubit.stackOperation(StackOperation.replace,
              screen: screen);
        }
        navigationKey?.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => screen?.build(context) ?? Container(),
            settings: RouteSettings(arguments: arguments),
          ),
        );
        break;
      case 'drawerOpen':
        Scaffold.maybeOf(arguments![0] as BuildContext)?.openDrawer();
        fvbNavigationBloc.model.drawer = true;
        fvbNavigationBloc.add(FvbNavigationChangedEvent());
        break;
      case 'drawerClose':
        Scaffold.maybeOf(arguments![0] as BuildContext)?.closeDrawer();
        fvbNavigationBloc.model.drawer = false;
        fvbNavigationBloc.add(FvbNavigationChangedEvent());
        break;
      case 'drawerEndOpen':
        Scaffold.maybeOf(arguments![0] as BuildContext)?.openEndDrawer();
        fvbNavigationBloc.model.drawer = true;
        fvbNavigationBloc.add(FvbNavigationChangedEvent());
        break;
      case 'drawerEndClose':
        Scaffold.maybeOf(arguments![0] as BuildContext)?.closeEndDrawer();
        fvbNavigationBloc.model.drawer = false;
        fvbNavigationBloc.add(FvbNavigationChangedEvent());
        break;
      case 'goback':
        stackActionCubit.stackOperation(StackOperation.pop);
        (navigationKey?.currentState as NavigatorState).pop();
        break;
      case 'refresh':
        if (split[1].isNotEmpty) {
          stateManagementBloc
              .add(StateManagementRefreshEvent(split[1], RuntimeMode.run));
        } else {
          stackActionCubit.update();
        }
        break;

      case 'lookup':
      // return out;
    }
  } else {
    // print('LOG::$message');
  }
}
