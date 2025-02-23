import 'package:flutter/material.dart';

import '../../common/analyzer/render_models.dart';
import '../../common/extension_util.dart';
import '../../components/component_list.dart';
import '../../components/holder_impl.dart';
import '../../constant/font_style.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/button/filled_button.dart';
import '../navigation/animated_dialog.dart';

bool needToCallHelper(Component component, Component parent) {
  if ((parent is CRow || parent is CColumn) &&
      component is! CRenderModel &&
      component is! CFlexModel) {
    return true;
  }
  return false;
}

bool unbounded(Component component) {
  if (component is! CRenderModel && component is! CFlexModel) {
    return true;
  }
  return false;
}

class ModificationHelper {
  final String name;
  final Component Function(Component) update;

  ModificationHelper(this.name, this.update);
}

class ComponentModificationHelper extends StatelessWidget {
  final ValueChanged<Component> onUpdated;
  final Component component;

  ComponentModificationHelper(
      {super.key, required this.onUpdated, required this.component});

  @override
  Widget build(BuildContext context) {
    final List<ModificationHelper> list = [
      if (unbounded(component)) ...[
        ModificationHelper('Expand', (p0) => CExpanded()..updateChild(p0)),
        ModificationHelper(
          'As it is',
          (p0) => p0,
        ),
      ]
    ];
    return Container(
      decoration: BoxDecoration(
        color: theme.background1,
        borderRadius: BorderRadius.circular(8),
      ),
      width: 240,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose',
                style: AppFontStyle.headerStyle(),
              ),
              const AppCloseButton(),
            ],
          ),
          20.hBox,
          for (final tile in list)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: FilledButtonWidget(
                onTap: () {
                  onUpdated.call(tile.update.call(component));
                  AnimatedDialog.hide(context);
                },
                text: tile.name,
              ),
            )
        ],
      ),
    );
  }
}
