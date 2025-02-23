import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/bloc/error/error_bloc.dart';
import 'package:flutter_builder/common/custom_popup_menu_button.dart';
import 'package:flutter_builder/constant/color_assets.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/runtime_provider.dart';
import 'package:flutter_builder/ui/component_tree/component_tree.dart';
import 'package:flutter_builder/ui/fvb_code_editor.dart';
import 'package:flutter_builder/ui/home/center_main_side.dart';
import 'package:flutter_builder/ui/home/home_page.dart';
import 'package:flutter_builder/ui/project/project_selection_page.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart' as slidingUp;

import 'package:flutterpilot_mobile/presentation/bloc/sliding_property/sliding_property_bloc.dart';

class MobileVisualEditor extends StatefulWidget {
  const MobileVisualEditor({super.key});

  @override
  State<MobileVisualEditor> createState() => _MobileVisualEditorState();
}

class _MobileVisualEditorState extends State<MobileVisualEditor> {
  Widget? drawerWidget;
  final SlidingPropertyBloc _slidingPropertyBloc = SlidingPropertyBloc();

  @override
  void initState() {
    super.initState();
    drawerWidget = const Drawer(
      width: 300,
      child: ComponentTree(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Scaffold(
                key: const GlobalObjectKey('ScaffoldKey'),
                resizeToAvoidBottomInset: false,
                body: SliderDrawer(
                  key: const GlobalObjectKey('slider_drawer'),
                  appBar: Container(),
                  slider: const ComponentTree(),
                  child: Stack(
                    children: [
                      CenterMainSide(
                          // slidingPropertyBloc: _slidingPropertyBloc,
                          ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Builder(builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(5),
                            child: RoundedAppIconButton(
                              iconSize: 24,
                              buttonSize: 40,
                              onPressed: () {
                                (const GlobalObjectKey('slider_drawer')
                                        .currentState as SliderDrawerState)
                                    .openSlider();
                              },
                              icon: Icons.list,
                              color: ColorAssets.theme,
                            ),
                          );
                        }),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: MediaQuery.of(context).size.height - 500,
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: StatefulBuilder(
                                  builder: (context, setState2) {
                                return Slider(
                                  value: _slidingPropertyBloc.value,
                                  activeColor: Colors.grey.withOpacity(0.5),
                                  inactiveColor: Colors.grey.withOpacity(0.8),
                                  onChanged: (newValue) {
                                    setState2(() {});
                                    _slidingPropertyBloc.add(
                                        SlidingPropertyChange(value: newValue));
                                  },
                                );
                              }),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ))),
        const SlidingPropertySection()
      ],
    );
  }
}

class SlidingPropertySection extends StatefulWidget {
  const SlidingPropertySection({Key? key}) : super(key: key);

  @override
  State<SlidingPropertySection> createState() => _SlidingPropertySectionState();
}

class _SlidingPropertySectionState extends State<SlidingPropertySection> {
  late final EventLogBloc _errorBloc;
  final panelController = slidingUp.PanelController();

  @override
  void initState() {
    _errorBloc = context.read<EventLogBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return slidingUp.SlidingUpPanel(
      panel: const ComponentPropertySection(),
      minHeight: 80,
      panelSnapping: true,
      snapPoint: 0.5,
      maxHeight: dh(context, 80),
      controller: panelController,
      onPanelSlide: (value) {
        if (value == 0) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
            }
          });
        }
      },
      collapsed: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: BlocBuilder<EventLogBloc, ErrorState>(
            bloc: _errorBloc,
            builder: (context, state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorBloc
                          .consoleMessages[RuntimeMode.edit]?.isNotEmpty ??
                      false)
                    SizedBox(
                      width: 150,
                      child: Text(
                        _errorBloc
                            .consoleMessages[RuntimeMode.edit]!.last.message,
                        style: AppFontStyle.lato(
                            _errorBloc.consoleMessages[RuntimeMode.edit]!.last
                                        .type ==
                                    ConsoleMessageType.event
                                ? 10
                                : 14,
                            color: getConsoleMessageColor(_errorBloc
                                .consoleMessages[RuntimeMode.edit]!.last.type),
                            fontWeight: _errorBloc
                                        .consoleMessages[RuntimeMode.edit]!
                                        .last
                                        .type ==
                                    ConsoleMessageType.event
                                ? FontWeight.w700
                                : FontWeight.w500),
                      ),
                    )
                  else
                    Text(
                      'No Messages',
                      style: AppFontStyle.lato(14, color: Colors.grey),
                    )
                ],
              );
            },
          ),
        ),
      ),
      onPanelClosed: () {},
    );
  }
}
