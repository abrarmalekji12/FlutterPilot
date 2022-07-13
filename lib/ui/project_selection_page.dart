import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/app_loader.dart';
import '../common/material_alert.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/authentication/authentication_cubit.dart';
import '../models/project_model.dart';
import '../cubit/flutter_project/flutter_project_cubit.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/landing_page.dart';

class ProjectSelectionPage extends StatefulWidget {
  final int userId;

  const ProjectSelectionPage({Key? key, required this.userId})
      : super(key: key);

  @override
  _ProjectSelectionPageState createState() => _ProjectSelectionPageState();
}

class _ProjectSelectionPageState extends State<ProjectSelectionPage> {
  late final FlutterProjectCubit _flutterProjectCubit;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flutterProjectCubit = context.read<FlutterProjectCubit>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _flutterProjectCubit.loadFlutterProjectList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      resizeToAvoidBottomInset: false,
      body: Padding(
          padding: const EdgeInsets.all(40),
          child: BlocListener<AuthenticationCubit, AuthenticationState>(
            listener: (context, state) {
              switch (state.runtimeType) {
                case AuthLoadingState:
                  AppLoader.show(context);
                  break;
                case AuthSuccessState:
                  AppLoader.hide();
                  if ((state as AuthSuccessState).userId == -1) {
                    Navigator.pop(context);
                    openAuthDialog(context, (userId) {});
                  }
                  break;
              }
            },
            child: BlocListener<FlutterProjectCubit, FlutterProjectState>(
              bloc: _flutterProjectCubit,
              listener: (context, state) {
                switch (state.runtimeType) {
                  case FlutterProjectLoadingState:
                    AppLoader.show(context);
                    break;
                  case FlutterProjectsLoadedState:
                    AppLoader.hide();
                    setState(() {});
                    break;
                  case FlutterProjectLoadedState:
                    break;
                  case FlutterProjectErrorState:
                    AppLoader.hide();
                    break;
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      BackButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      const LogoutButton(),
                    ],
                  ),
                  const Divider(
                    color: AppColors.lightGrey,
                    thickness: 1,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Start with Project',
                    style: GoogleFonts.getFont(
                      'Roboto',
                      textStyle: const TextStyle(
                        fontSize: 20,
                        color: Color(0xff000000),
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Form(
                    key: _formKey,
                    child: SizedBox(
                      width: 400,
                      child: RoundBorderedTextField(
                        controller: _textEditingController,
                        hint: 'Enter Project Name',
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    final name = _textEditingController.text;
                                    _flutterProjectCubit
                                        .createNewProject(name)
                                        .then((value) {
                                      _textEditingController.text = '';
                                      setState(() {});
                                      Navigator.pushNamed(context, '/projects',
                                          arguments: [widget.userId, name]);
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.theme,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        'Create new project',
                                        style: GoogleFonts.getFont(
                                          'Roboto',
                                          textStyle: AppFontStyle.roboto(15,
                                              color: Colors.white),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Icon(
                                        Icons.done,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Text(
                            'Or choose an existing one',
                            style: GoogleFonts.getFont(
                              'Roboto',
                              textStyle: AppFontStyle.roboto(15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Wrap(
                                children: _flutterProjectCubit.projects
                                    .map(
                                      (project) => ProjectTile(
                                          name: project.name,
                                          id: widget.userId,
                                          project: project),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          )),
    );
  }
}

class ProjectTile extends StatelessWidget {
  final String name;
  final FlutterProject project;
  final int id;

  const ProjectTile(
      {Key? key, required this.name, required this.id, required this.project})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, bottom: 10),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/projects',
                      arguments: [id, name]);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.theme,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    name,
                    style: AppFontStyle.roboto(14, color: Colors.white),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            AppIconButton(
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                Navigator.pushNamed(context, '/run', arguments: [id, name]);
              },
              color: AppColors.green,
            ),
            const SizedBox(
              width: 5,
            ),
            AppIconButton(
              icon: Icons.delete,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => MaterialAlertDialog(
                    title:
                        'Do you really want to delete this project?, you will not be able to get back',
                    positiveButtonText: 'delete',
                    negativeButtonText: 'cancel',
                    onPositiveTap: () {
                      context
                          .read<FlutterProjectCubit>()
                          .deleteProject(project);
                    },
                  ),
                );
              },
              color: AppColors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final double buttonSize;
  final VoidCallback onPressed;
  final Color color;

  const AppIconButton(
      {Key? key,
      required this.icon,
      required this.onPressed,
      required this.color,
      this.iconSize = 14,
      this.buttonSize = 24})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(buttonSize/2)
      ,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: kElevationToShadow[2]),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
      onTap: onPressed,
    );
  }
}

class RoundBorderedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const RoundBorderedTextField(
      {Key? key, required this.controller, required this.hint})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.getFont(
        'Roboto',
        textStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xff000000),
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 3) {
          return 'Project name should be greater than 3 characters';
        }
        return null;
      },
      readOnly: false,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(10),
        labelText: hint,
        labelStyle: GoogleFonts.getFont(
          'Roboto',
          textStyle: AppFontStyle.roboto(14, color: Colors.grey.shade700),
        ),
        hintStyle: AppFontStyle.roboto(14, color: Colors.black),
        prefixText: '',
        suffixText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xfff7f7f7),
            width: 2,
          ),
        ),
        enabled: true,
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showDialog(
            context: context,
            builder: (_) {
              return MaterialAlertDialog(
                subtitle: 'Are you sure, you want to logout?',
                positiveButtonText: 'Yes',
                negativeButtonText: 'No',
                onPositiveTap: () {
                  BlocProvider.of<AuthenticationCubit>(context)
                      .logout();
                },
              );
            });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.theme,
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              'Logout',
              style: AppFontStyle.roboto(15,
                  color: AppColors.darkGrey, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }
}
