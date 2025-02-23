import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/navigation/fvb_navigation_bloc.dart';
import '../common/app_switch.dart';
import '../common/extension_util.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../constant/string_constant.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../injector.dart';
import '../models/fvb_ui_core/component/custom_component.dart';
import 'controls_widget.dart';

class NavigationModel {
  bool dialog = false;
  CustomComponent? dialogComp;
  CustomComponent? bottomComp;
  bool drawer = false;
  bool endDrawer = false;
  bool bottomSheet = false;
}

class FVBDialog {
  final CustomComponent dialog;

  FVBDialog(this.dialog);
}

class NavigationSettingsView extends StatefulWidget {
  const NavigationSettingsView({Key? key}) : super(key: key);

  @override
  State<NavigationSettingsView> createState() => _NavigationSettingsViewState();
}

class _NavigationSettingsViewState extends State<NavigationSettingsView> {
  final FvbNavigationBloc _fvbNavigationBloc = sl<FvbNavigationBloc>();
  late SelectionCubit selectionCubit;

  @override
  void initState() {
    selectionCubit = context.read<SelectionCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FvbNavigationBloc, FvbNavigationState>(
      bloc: _fvbNavigationBloc,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SliderBackButton(),
                10.wBox,
                Text(
                  'Screen Config',
                  style: AppFontStyle.subtitleStyle(),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            BlocBuilder(
                bloc: selectionCubit,
                builder: (context, state) {
                  if (selectionCubit.selected.viewable != null) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 16,
                              color: ColorAssets.theme,
                            ),
                            10.wBox,
                            Text(
                              selectionCubit.selected.viewable!.name,
                              style: AppFontStyle.lato(13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.text1Color),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        AppSwitchTile(
                          title: 'Drawer',
                          value: _fvbNavigationBloc
                              .isDrawerOpen(selectionCubit.selected.viewable!),
                          onChange: (value) {
                            _fvbNavigationBloc.toggleDrawer(
                                screen: selectionCubit.selected.viewable!);
                            setState(() {});
                          },
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        AppSwitchTile(
                          title: 'End Drawer',
                          value: _fvbNavigationBloc.isEndDrawerOpen(
                              selectionCubit.selected.viewable!),
                          onChange: (value) {
                            _fvbNavigationBloc.toggleEndDrawer(
                                screen: selectionCubit.selected.viewable!);
                            setState(() {});
                          },
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                      ],
                    );
                  }
                  return const Offstage();
                }),
            if (_fvbNavigationBloc.model.dialog)
              AppSwitchTile(
                title: 'Dialog',
                value: _fvbNavigationBloc.model.dialog,
                onChange: (value) {
                  if (!value) {
                    navigationKey?.currentState?.pop();
                    _fvbNavigationBloc.model.dialog = false;
                    context.read<CreationCubit>().changedComponent();
                    _fvbNavigationBloc.add(FvbNavigationChangedEvent());
                  }
                },
              ),
            const SizedBox(
              height: 8,
            ),
            if (_fvbNavigationBloc.model.bottomSheet)
              AppSwitchTile(
                title: 'Bottom Sheet',
                value: _fvbNavigationBloc.model.bottomSheet,
                onChange: (value) {
                  if (!value) {
                    _fvbNavigationBloc.persistentBottomSheetController?.close();
                    _fvbNavigationBloc.model.bottomSheet = false;
                    context.read<CreationCubit>().changedComponent();
                    _fvbNavigationBloc.add(FvbNavigationChangedEvent());
                  }
                },
              )
          ],
        );
      },
    );
  }
}

class AppSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChange;

  const AppSwitchTile(
      {Key? key,
      required this.title,
      required this.value,
      required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppFontStyle.lato(13,
              color: theme.text1Color, fontWeight: FontWeight.normal),
        ),
        const SizedBox(
          width: 10,
        ),
        AppSwitch(
            value: value,
            onToggle: (val) {
              onChange.call(val);
            }),
      ],
    );
  }
}
