import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/extension_util.dart';
import '../../common/firebase_image.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../common/validations.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../injector.dart';
import '../../models/project_model.dart';
import '../../models/templates/template_model.dart';
import '../../widgets/button/app_close_button.dart';
import '../../widgets/common_circular_loading.dart';
import '../../widgets/loading/overlay_loading_component.dart';
import '../../widgets/textfield/app_textfield.dart';
import '../navigation/animated_dialog.dart';
import 'project_selection_page.dart';
import 'widgets/template_viewer.dart';

class ProjectCreationDialog extends StatefulWidget {
  final List<String> projects;
  final String userId;
  final ValueChanged<FVBProject> onCreated;

  const ProjectCreationDialog(
      {super.key,
      required this.projects,
      required this.userId,
      required this.onCreated});

  @override
  State<ProjectCreationDialog> createState() => _ProjectCreationDialogState();
}

class _ProjectCreationDialogState extends State<ProjectCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingController = TextEditingController();
  final UserDetailsCubit _userDetailsCubit = sl();
  List<FVBTemplate> templates = [];
  FVBTemplate? selectedTemplate;

  @override
  void initState() {
    super.initState();
    _userDetailsCubit.loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer(
      listener: (context, state) {
        if (state is ProjectTemplatesLoadedState) {
          templates = state.templates;
        }
      },
      bloc: _userDetailsCubit,
      buildWhen: (_, state) =>
          state is ProjectCreationLoadingState ||
          state is UserDetailsErrorState,
      builder: (context, state) {
        return OverlayLoadingComponent(
          radius: 10,
          loading: state is ProjectCreationLoadingState,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create a new Project',
                      style: AppFontStyle.headerStyle(),
                      textAlign: TextAlign.left,
                    ),
                    const AppCloseButton()
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Form(
                  key: _formKey,
                  child: SizedBox(
                    width:
                        !Responsive.isMobile(context) ? 500 : double.infinity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _textEditingController,
                            hintText: 'Name',
                            validator: (value) {
                              if (state is ProjectCreationLoadingState) {
                                return null;
                              }
                              if ([...widget.projects, 'Custom']
                                  .contains(value)) {
                                return 'this project name already exists';
                              }
                              return Validations.projectNameValidator()
                                  .call(value);
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        SizedBox(
                          height: 50,
                          child: InkResponse(
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                final name = _textEditingController.text;

                                _userDetailsCubit
                                    .createProject(name,
                                        template: selectedTemplate)
                                    .then((project) async {
                                  if (project != null) {
                                    _textEditingController.text = '';
                                    await AnimatedDialog.hide(context);
                                    widget.onCreated.call(project);
                                  }
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: ColorAssets.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: const Offset(1, 1))
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.arrow_forward,
                                size: 22,
                                color: ColorAssets.theme,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                BlocBuilder(
                  bloc: _userDetailsCubit,
                  buildWhen: (_, state) =>
                      state is ProjectTemplatesLoadingState ||
                      state is ProjectTemplatesLoadedState,
                  builder: (context, state) {
                    if (state is ProjectTemplatesLoadingState) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CommonCircularLoading(),
                      );
                    }
                    if (templates.isEmpty) {
                      return const Offstage();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Template',
                          style: AppFontStyle.titleStyle(),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedTemplate = null;
                                });
                              },
                              child: DottedBorder(
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(6),
                                dashPattern: [4, 4],
                                strokeCap: StrokeCap.round,
                                strokeWidth: 2,
                                color: selectedTemplate == null
                                    ? ColorAssets.theme
                                    : ColorAssets.grey,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Blank',
                                    style: AppFontStyle.lato(
                                      16,
                                      color: selectedTemplate == null
                                          ? ColorAssets.theme
                                          : ColorAssets.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ...templates
                                .map(
                                  (e) => InkWell(
                                    onTap: () {
                                      selectedTemplate = e;
                                      setState(() {});
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      clipBehavior: Clip.hardEdge,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color: e == selectedTemplate
                                                ? ColorAssets.theme
                                                    .withOpacity(0.5)
                                                : Colors.transparent,
                                            width:
                                                e == selectedTemplate ? 2 : 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: theme.background1,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 8,
                                            )
                                          ]),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Text(
                                              e.name,
                                              style: AppFontStyle.lato(16.sp,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            width: 400,
                                            height: 400,
                                            child: Stack(
                                              alignment: Alignment.centerLeft,
                                              children: [
                                                for (final url in e
                                                    .imageURLs.reversed.indexed)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        left: (e.imageURLs
                                                                    .length -
                                                                url.$1 -
                                                                1) *
                                                            50),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          boxShadow: [
                                                            BoxShadow(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.2),
                                                                blurRadius: 24,
                                                                spreadRadius: 8)
                                                          ],
                                                          color: Colors.white),
                                                      clipBehavior:
                                                          Clip.hardEdge,
                                                      child: FirebaseImage(
                                                        url.$2,
                                                        width: 150,
                                                        errorBuilder:
                                                            (context, _, __) =>
                                                                Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Icon(
                                                              Icons.image,
                                                              size: 50,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            20.hBox,
                                                            Text(
                                                              'Image not found',
                                                              style:
                                                                  AppFontStyle
                                                                      .lato(
                                                                16,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        fit: BoxFit.scaleDown,
                                                      ),
                                                    ),
                                                  ),
                                                Align(
                                                  alignment: Alignment.topRight,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: RoundedAppIconButton(
                                                      buttonSize: 30,
                                                      icon:
                                                          Icons.remove_red_eye,
                                                      onPressed: () {
                                                        AnimatedDialog.show(
                                                          context,
                                                          TemplateViewerWidget(
                                                              template: e),
                                                          key: 'template',
                                                        );
                                                      },
                                                      color: ColorAssets.theme,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          if (e.description.trim().isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                e.description,
                                                style: AppFontStyle.lato(
                                                  14,
                                                  color: ColorAssets.darkerGrey,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList()
                          ],
                        ),
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
