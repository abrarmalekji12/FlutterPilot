import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../collections/project_info_collection.dart';
import '../../common/app_button.dart';
import '../../common/common_methods.dart';
import '../../common/validations.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/component_operation/operation_cubit.dart';
import '../../injector.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';

final UserProjectCollection _collection = sl<UserProjectCollection>();

class ComponentTileTree extends StatelessWidget {
  final CustomComponent component;

  const ComponentTileTree({Key? key, required this.component})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (component.rootComponent == null) {
      return const Offstage();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              component.name,
              style: AppFontStyle.lato(14,
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (component.project != _collection.project!.name)
                  AppIconButton(
                      size: 16,
                      margin: 4,
                      icon: Icons.add,
                      background: ColorAssets.theme,
                      onPressed: () {
                        showEnterInfoDialog(
                            context, 'Rename "${component.name}"',
                            initialValue: component.name, onPositive: (value) {
                          final clone = (component.clone(null, deepClone: true)
                              as CustomComponent);
                          clone.name = value;
                          clone.project = _collection.project!;
                          _collection.project!.customComponents.add(clone);
                          context
                              .read<OperationCubit>()
                              .saveCustomComponent(clone);
                        }, validator: (value) {
                          if (value == component.name) {
                            return 'Please enter different name';
                          }
                          return Validations.commonNameValidator()(value);
                        });
                      })
              ],
            )
          ],
        ),
        ComponentTileWidget(
          component: component.rootComponent!,
        ),
      ],
    );
  }
}

class ComponentTileWidget extends StatelessWidget {
  final Component component;

  const ComponentTileWidget({Key? key, required this.component})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.grey.shade300.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            component.name,
            style: AppFontStyle.lato(13,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),
          if (component is Holder && (component as Holder).child != null)
            Container(
              decoration: const BoxDecoration(
                  border:
                      Border(left: BorderSide(width: 1, color: Colors.grey))),
              padding: const EdgeInsets.only(left: 8.0),
              child: ComponentTileWidget(
                component: (component as Holder).child!,
              ),
            )
          else if (component is MultiHolder)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(width: 1, color: Colors.grey),
                ),
              ),
              padding: const EdgeInsets.only(left: 8.0),
              child: ListView.builder(
                itemBuilder: (context, i) {
                  return ComponentTileWidget(
                      component: (component as MultiHolder).children[i]);
                },
                itemCount: (component as MultiHolder).children.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
              ),
            )
          else if (component is CustomNamedHolder) ...[
            for (final child
                in (component as CustomNamedHolder).childMap.entries)
              if (child.value != null) ...[
                Text(
                  child.key,
                  style: AppFontStyle.lato(13, color: theme.text3Color),
                ),
                ComponentTileWidget(component: child.value!)
              ],
            for (final child
                in (component as CustomNamedHolder).childrenMap.entries)
              if (child.value.isNotEmpty) ...[
                Text(
                  child.key,
                  style: AppFontStyle.lato(13, color: theme.text3Color),
                ),
                ListView.builder(
                  itemBuilder: (context, i) {
                    return ComponentTileWidget(component: child.value[i]);
                  },
                  itemCount: child.value.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                )
              ]
          ]
        ],
      ),
    );
  }
}
