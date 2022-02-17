import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../runtime_provider.dart';
import '../home_page.dart';

class BuildView extends StatelessWidget {
  final Function onDismiss;
  final ScreenConfigCubit screenConfigCubit;
  final ComponentOperationCubit componentOperationCubit;

  const BuildView(
      {Key? key,
      required this.onDismiss,
      required this.screenConfigCubit,
      required this.componentOperationCubit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    componentOperationCubit.runtimeMode = RuntimeMode.run;
    return GestureDetector(
      onTap: (){
        _onDismiss();
      },
      child: Material(
        color: Colors.black.withOpacity(0.4),
        child: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  ScreenConfigSelection(
                    componentOperationCubit: componentOperationCubit,
                    screenConfigCubit: screenConfigCubit,
                  ),
                  Expanded(
                    child: RuntimeProvider(
                      runtimeMode: RuntimeMode.run,
                      child: BlocBuilder<ComponentOperationCubit,
                          ComponentOperationState>(
                        bloc: componentOperationCubit,
                        builder: (context, state) {
                          return Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 1)),
                            child: FittedBox(
                              child: Container(
                                width: screenConfigCubit.screenConfig.width,
                                height: screenConfigCubit.screenConfig.height,
                                color: Colors.white,
                                child: componentOperationCubit
                                    .flutterProject!.run(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  _onDismiss();
                },
                child: const Icon(Icons.close),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onDismiss() {
    componentOperationCubit.runtimeMode = RuntimeMode.edit;
    onDismiss.call();
    Get.back();
  }
}
