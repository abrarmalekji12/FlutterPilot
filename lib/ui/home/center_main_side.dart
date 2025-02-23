import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/extension_util.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../cubit/screen_config/screen_config_cubit.dart';
import '../../injector.dart';
import '../../models/component_selection.dart';
import '../../runtime_provider.dart';
import 'editing_view.dart';
import 'home_page.dart';

class CenterMainSide extends StatefulWidget {
  // final SlidingPropertyBloc? slidingPropertyBloc;

  const CenterMainSide({
    Key? key,
    // this.slidingPropertyBloc,
  }) : super(key: key);

  @override
  State<CenterMainSide> createState() => _CenterMainSideState();
}

class _CenterMainSideState extends State<CenterMainSide> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RuntimeProvider(
      runtimeMode: RuntimeMode.edit,
      child: Container(
        alignment: Alignment.center,
        color: ColorAssets.colorE5E5E5,
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
                    builder: (_, state) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 60, top: 10),
                            child: ToolbarButtons(),
                          ),
                          Expanded(
                            child:
                                // Responsive(
                                // mobile: BlocBuilder<SlidingPropertyBloc, SlidingPropertyState>(
                                //   bloc: widget.slidingPropertyBloc,
                                //   builder: (context, state) {
                                //     return Transform.translate(
                                //       offset: Offset(0, -(1 - (widget.slidingPropertyBloc?.value ?? 0)) * 500),
                                //       child: const EditingView(),
                                //     );
                                //   },
                                // ),
                                // desktop:
                                EditingView(),
                            // ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: ErrorListingWidget(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorListingWidget extends StatefulWidget {
  const ErrorListingWidget({Key? key}) : super(key: key);

  @override
  State<ErrorListingWidget> createState() => _ErrorListingWidgetState();
}

class _ErrorListingWidgetState extends State<ErrorListingWidget> {
  late SelectionCubit selectionCubit;
  final ValueNotifier<bool> _visibility = ValueNotifier(false);

  @override
  void initState() {
    selectionCubit = context.read<SelectionCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectionCubit, SelectionState>(
        bloc: selectionCubit,
        // buildWhen: (_, state) => state is ComponentSelectionErrorChangeState,
        builder: (context, state) {
          return Material(
            color: Colors.transparent,
            child: AnimatedSize(
              alignment: Alignment.bottomCenter,
              duration: const Duration(milliseconds: 200),
              child: selectionCubit.errorList.isEmpty
                  ? const Offstage()
                  : Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.background1,
                        boxShadow: kElevationToShadow[3],
                      ),
                      width: 500,
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              _visibility.value = !_visibility.value;
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Badge(
                                    label: Text(selectionCubit.errorList.length
                                        .toString()),
                                    isLabelVisible:
                                        selectionCubit.errorList.isNotEmpty,
                                    child: SizedBox(
                                      width: 70,
                                      child: IntrinsicWidth(
                                        child: Text(
                                          'Analysis',
                                          style: AppFontStyle.lato(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ValueListenableBuilder(
                                      valueListenable: _visibility,
                                      builder: (context, value, _) {
                                        return Icon(
                                          !value
                                              ? Icons
                                                  .keyboard_arrow_down_rounded
                                              : Icons.keyboard_arrow_up_rounded,
                                        );
                                      })
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          ValueListenableBuilder(
                            valueListenable: _visibility,
                            builder: (context, value, child) {
                              if (value) {
                                return child ?? const Offstage();
                              }
                              return const Offstage();
                            },
                            child: Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(4),
                                separatorBuilder: (context, i) =>
                                    const SizedBox(
                                  height: 4,
                                ),
                                itemBuilder: (context, i) {
                                  final error = selectionCubit.errorList[i];
                                  return InkWell(
                                    onTap: () {
                                      final ancestor = error.component.ancestor;
                                      sl<SelectionCubit>()
                                          .changeComponentSelection(
                                        ComponentSelectionModel.unique(
                                          error.component,
                                          ancestor.component,
                                          screen: ancestor.screen,
                                        ),
                                        parameter: error.parameter,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color: ColorAssets.colorD0D5EF,
                                            width: 0.6,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            '${error.component.name} · ',
                                                        style:
                                                            AppFontStyle.lato(
                                                                13,
                                                                color:
                                                                    ColorAssets
                                                                        .theme,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700),
                                                      ),
                                                      if (error.parameter !=
                                                          null)
                                                        TextSpan(
                                                          text:
                                                              '${error.parameter!.displayName ?? error.parameter!.info.getName() ?? ''}',
                                                          style:
                                                              AppFontStyle.lato(
                                                            13,
                                                            color: ColorAssets
                                                                .green,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                4.hBox,
                                                Text(
                                                  '${error.errorMessage}·',
                                                  style: AppFontStyle.lato(13,
                                                      color: theme.text2Color,
                                                      fontWeight:
                                                          FontWeight.normal),
                                                )
                                              ],
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.all(3.0),
                                            child: Icon(
                                              Icons.chevron_right,
                                              size: 22,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                itemCount: selectionCubit.errorList.length,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
            ),
          );
        });
  }
}
