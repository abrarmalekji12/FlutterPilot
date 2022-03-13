import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../runtime_provider.dart';

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
      onTap: () {
        _onDismiss();
      },
      child: Material(
        color: Colors.white,
        child: Stack(
          children: [
            Center(
              child: RuntimeProvider(
                runtimeMode: RuntimeMode.run,
                child: BlocBuilder<ComponentOperationCubit,
                    ComponentOperationState>(
                  bloc: componentOperationCubit,
                  builder: (_, state) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: GestureDetector(
                        onTap: () {},
                        child: DevicePreview(

                          tools: const [
                            DeviceSection()
                          ],
                          builder: (_) {
                            return LayoutBuilder(builder: (_, constraints) {
                              ComponentOperationCubit
                                  .codeProcessor
                                  .variables['dw']!
                                  .value = constraints.maxWidth;
                              ComponentOperationCubit
                                  .codeProcessor
                                  .variables['dh']!
                                  .value = constraints.maxHeight;
                              return SafeArea(
                                child: componentOperationCubit.flutterProject!
                                    .run(context, navigator: true),
                              );
                            });
                          },
                          enabled: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _onDismiss();
                  },
                  child: const Icon(Icons.arrow_back),
                ),
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
