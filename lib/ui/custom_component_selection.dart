import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../injector.dart';
import '../runtime_provider.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/message/empty_text.dart';
import 'component_tree/component_tile_tree.dart';
import 'navigation/animated_dialog.dart';

class CustomComponentSelection extends StatefulWidget {
  const CustomComponentSelection({Key? key}) : super(key: key);

  @override
  State<CustomComponentSelection> createState() =>
      _CustomComponentSelectionState();
}

class _CustomComponentSelectionState extends State<CustomComponentSelection> {
  late OperationCubit componentOperationCubit;

  @override
  void initState() {
    componentOperationCubit = context.read<OperationCubit>();
    if (componentOperationCubit.allCustoms == null) {
      componentOperationCubit.loadAllCustomComponents();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Material(
        color: Colors.transparent,
        child: Align(
          child: Container(
            width: 500,
            height: 600,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: theme.background1,
                borderRadius: BorderRadius.circular(10)),
            child: RuntimeProvider(
              runtimeMode: RuntimeMode.favorite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose Custom Widget',
                        style: AppFontStyle.headerStyle(),
                      ),
                      AppCloseButton(
                        onTap:()=> AnimatedDialog.hide(context),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: BlocBuilder<OperationCubit, OperationState>(
                      builder: (context, state) {
                        if (componentOperationCubit.allCustoms != null) {
                          if (componentOperationCubit.allCustoms!.isEmpty) {
                            return const EmptyTextIconWidget(
                              text: 'No custom-components',
                              icon: Icons.pages_rounded,
                            );
                          }
                          return ListView(
                            children: [
                              for (final customs in componentOperationCubit
                                  .allCustoms!.entries)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customs.key,
                                        style: AppFontStyle.lato(14,
                                            color: ColorAssets.theme,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Wrap(
                                        children: customs.value
                                            .map((e) => ComponentTileTree(
                                                  component: e,
                                                ))
                                            .toList(growable: false),
                                      )
                                    ],
                                  ),
                                )
                            ],
                          );
                        }
                        return const Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
