import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/extension_util.dart';
import '../../constant/font_style.dart';
import '../../constant/preference_key.dart';
import '../../cubit/stack_action/stack_action_cubit.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../injector.dart';
import '../../runtime_provider.dart';
import '../../user_session.dart';
import '../../widgets/app_back_button.dart';

class RunModeWidget extends StatefulWidget {
  final VoidCallback? onBack;
  const RunModeWidget({Key? key, this.onBack}) : super(key: key);

  @override
  State<RunModeWidget> createState() => _RunModeWidgetState();
}

class _RunModeWidgetState extends State<RunModeWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.background1,
      child: BlocConsumer<UserDetailsCubit, UserDetailsState>(
        buildWhen: (state1, state2) {
          if (state2 is ProjectLoadingState) {
            return false;
          }
          return true;
        },
        listener: (context, state) {
          if (state is FlutterProjectLoadedState) {}
        },
        builder: (context, state) {
          if (collection.project != null) {
            // final consoleWidthFraction = 400 / MediaQuery.of(context).size.width;
            sl<StackActionCubit>().stackOperation(StackOperation.push,
                screen: collection.project!.mainScreen);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      AppBackButton(
                        onTap: widget.onBack ??
                            () {
                              sl<SharedPreferences>().remove(PrefKey.projectId);
                              Navigator.of(context, rootNavigator: true)
                                  .pushReplacementNamed('/projects',
                                      arguments: sl<UserSession>().user.userId);
                            },
                      ),
                      20.wBox,
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                      20.wBox,
                      Text(
                        collection.project!.name,
                        style: AppFontStyle.titleStyle(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                    child: RuntimeProvider(
                  runtimeMode: RuntimeMode.run,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return collection.project!
                          .run(context, constraints, navigator: true);
                    },
                  ),
                )
                    // RuntimeProvider(
                    //   runtimeMode: RuntimeMode.run,
                    //   child: StreamBuilder<Component>(
                    //       stream: dataBridge.loadMainScreen(
                    //         collection.project!,
                    //         context.read<OperationCubit>(),
                    //       ),
                    //       builder: (context, comp) {
                    //         if (comp.hasData && comp.data != null) {
                    //           collection.project!.mainScreen?.rootComponent = comp.data;
                    //           final size = MediaQuery.of(context).size;
                    //           return collection.project!.run(
                    //               context, BoxConstraints(maxWidth: size.width, maxHeight: size.height),
                    //               navigator: true);
                    //         }
                    //         return const Offstage();
                    //       }),
                    // )

                    //   ResizableWidget(
                    //     percentages: [
                    //       1 - consoleWidthFraction,
                    //       consoleWidthFraction,
                    //     ],
                    //     children: [
                    //       CustomDevicePreview(builder: (context) {
                    //         return ;
                    //       }),
                    //       const ConsoleWidget(mode: RuntimeMode.run)
                    //     ],
                    //   ),
                    ),
              ],
            );
          }
          return const Offstage();
        },
      ),
    );
  }
}
