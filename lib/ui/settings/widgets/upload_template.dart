
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/app_button.dart';
import '../../../common/button_loading_widget.dart';
import '../../../common/custom_drop_down.dart';
import '../../../common/extension_util.dart';
import '../../../constant/color_assets.dart';
import '../../../constant/font_style.dart';
import '../../../cubit/component_operation/operation_cubit.dart';
import '../../../cubit/component_selection/component_selection_cubit.dart';
import '../../../data/remote/firestore/firebase_bridge.dart';
import '../../../injector.dart';
import '../../../models/common_mixins.dart';
import '../../../models/fvb_ui_core/component/custom_component.dart';
import '../../../models/project_model.dart';
import '../../../models/template_model.dart';
import '../../../models/variable_model.dart';
import '../../../widgets/textfield/app_textfield.dart';
import '../../boundary_widget.dart';



class UploadTemplateWidget extends StatefulWidget {
  const UploadTemplateWidget({Key? key}) : super(key: key);

  @override
  State<UploadTemplateWidget> createState() => _UploadTemplateWidgetState();
}

class _UploadTemplateWidgetState extends State<UploadTemplateWidget>
    with CustomComponentExtractor {
  late final OperationCubit _operationCubit;
  late final SelectionCubit _selectionCubit;
  Viewable? screen;
  final TextEditingController _nameController = TextEditingController(),
      _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _operationCubit = context.read<OperationCubit>();
    _selectionCubit = context.read<SelectionCubit>();
    screen = _selectionCubit.selected.viewable;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: AppTextField(
              controller: _nameController,
              title: 'Name',
              required: true,
              height: 35,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 250,
            child: AppTextField(
              controller: _descriptionController,
              title: 'Description',
              height: 35,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 250,
            child: FormField(
                initialValue: screen,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (object) {
                  if (screen != null) {
                    final report = _operationCubit.validateComponent(
                        screen!.rootComponent!,
                        screen!.rootComponent!,
                        screen,
                        [_operationCubit.project!.scopeName]);
                    print(
                        'VALIDATE ${report?.error} ${report?.componentError}');
                    if (report != null) {
                      final keyList =
                      report.componentError.keys.toList(growable: false);
                      return '${report.componentError.entries.length} errors found!\n ${report.componentError.entries.map((e) => '(${keyList.indexOf(e.key) + 1}) ${e.key.id} => ${e.value}').join('\n')}';
                    }

                    final List<CustomComponent> list = [];
                    if (screen!.rootComponent != null)
                      extractCustomComponents(screen!.rootComponent!, list);
                    for (final custom in list) {
                      if (custom.rootComponent != null) {
                        final report = _operationCubit.validateComponent(
                          custom.rootComponent!,
                          custom.rootComponent!,
                          screen,
                          [collection.project!.scopeName],
                        );
                        if (report != null) {
                          return 'This screen depends on ${custom.name}, but in ${custom.name}, ${report.errorCount} errors found!\n ${report.componentError.entries.map((e) => '${e.key.name} => ${e.value}').join('\n')}';
                        }
                      }
                    }
                    return null;
                  }

                  return 'Please select screen';
                },
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Screen',
                        style: AppFontStyle.lato(
                          14,
                          fontWeight: FontWeight.w400,
                          color: ColorAssets.color333333,
                        ),
                      ),
                      10.hBox,
                      CustomDropdownButton<Viewable>(
                          style: AppFontStyle.lato(13),
                          value: screen,
                          hint: Text(
                            'Select Screen',
                            style: AppFontStyle.lato(14),
                          ),
                          items: _operationCubit.project!.screens
                              .map<CustomDropdownMenuItem<Screen>>(
                                (e) => CustomDropdownMenuItem<Screen>(
                              value: e,
                              child: Text(
                                e.name,
                                style: AppFontStyle.lato(
                                  13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.text1Color,
                                ),
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != screen) {
                              screen = value;
                              setState(() {});
                            }
                          },
                          selectedItemBuilder: (context, config) {
                            return Text(
                              config.name,
                              style: AppFontStyle.lato(
                                13,
                                fontWeight: FontWeight.w500,
                                color: theme.text1Color,
                              ),
                            );
                          }),
                      if (state.hasError) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          state.errorText ?? 'ERROR',
                          style: AppFontStyle.lato(14, color: ColorAssets.red),
                        )
                      ]
                    ],
                  );
                }),
          ),
          const SizedBox(
            height: 15,
          ),
          BlocBuilder<OperationCubit, OperationState>(
            builder: (context, state) {
              if (state is ComponentOperationTemplateUploadingState) {
                return const ButtonLoadingWidget();
              }
              return Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  width: 120,
                  height: 45,
                  title: 'Submit',
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _nameController.text.isNotEmpty &&
                        screen != null) {
                      final model = TemplateModel(
                        screen! as Screen,
                        _operationCubit.project!.variables.values
                            .whereType<VariableModel>()
                            .where((element) =>
                        element.uiAttached && element.deletable)
                            .toList(growable: false),
                        _nameController.text,
                        _descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : null,
                        _operationCubit.project!.userId,
                        DateTime.now(),
                        id: randomId,
                      );
                      model.images.addAll(model.extractedImages);
                      model.customComponents.addAll(model.extractedCustoms);
                      _operationCubit.uploadTemplate(model);
                    }
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
