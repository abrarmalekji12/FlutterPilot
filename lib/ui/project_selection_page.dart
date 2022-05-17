import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/app_loader.dart';
import '../common/material_alert.dart';
import '../constant/font_style.dart';
import '../cubit/authentication/authentication_cubit.dart';
import '../models/project_model.dart';
import 'authentication/login.dart';
import 'home_page.dart';
import 'package:get/get.dart';
import '../cubit/flutter_project/flutter_project_cubit.dart';
import 'package:google_fonts/google_fonts.dart';

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
    _flutterProjectCubit = FlutterProjectCubit(widget.userId);
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
                  Get.offAll(() => const LoginPage());
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
                  Container(
                    height: 56,
                    child: Row(
                      children: const [Spacer(), LogoutButton()],
                    ),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: Color(0xfff2f2f2), width: 1))),
                  ),
                  Text(
                    'Projects',
                    style: GoogleFonts.getFont(
                      'Roboto',
                      textStyle: const TextStyle(
                        fontSize: 21,
                        color: Color(0xff000000),
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _textEditingController,
                      style: GoogleFonts.getFont(
                        'Roboto',
                        textStyle: const TextStyle(
                          fontSize: 18,
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
                        contentPadding: const EdgeInsets.all(15),
                        labelText: 'Please enter project name',
                        labelStyle: GoogleFonts.getFont(
                          'Roboto',
                          textStyle: const TextStyle(
                            fontSize: 15,
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        helperStyle: GoogleFonts.getFont(
                          'ABeeZee',
                          textStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        hintStyle: GoogleFonts.getFont(
                          'ABeeZee',
                          textStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        errorStyle: GoogleFonts.getFont(
                          'ABeeZee',
                          textStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        icon: const Icon(
                          Icons.create,
                        ),
                        iconColor: const Color(0xffffffff),
                        prefixText: '',
                        prefixStyle: GoogleFonts.getFont(
                          'ABeeZee',
                          textStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        suffixText: '',
                        suffixStyle: GoogleFonts.getFont(
                          'ABeeZee',
                          textStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        enabled: true,
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
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final name = _textEditingController.text;
                                    _flutterProjectCubit
                                        .createNewProject(name)
                                        .then((value) {
                                      _textEditingController.text = '';
                                      setState(() {});
                                      Get.to(
                                          () => HomePage(
                                                projectName: name,
                                                userId: widget.userId,
                                              ),
                                          routeName: 'projects/$name');
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      const Icon(
                                        Icons.add,
                                        size: 35,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Create new project',
                                        style: GoogleFonts.getFont(
                                          'Roboto',
                                          textStyle: const TextStyle(
                                            fontSize: 21,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        textAlign: TextAlign.left,
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
                            'Or choose an existing project',
                            style: GoogleFonts.getFont(
                              'Roboto',
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
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
                                    .map((project) => Padding(
                                          padding: const EdgeInsets.only(
                                              right: 10, bottom: 10),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  Get.to(
                                                      () => HomePage(
                                                            projectName:
                                                                project.name,
                                                            userId:
                                                                widget.userId,
                                                          ),
                                                      routeName:
                                                          '/projects/${project.name}');
                                                },
                                                child: Text(
                                                  project.name,
                                                  style: GoogleFonts.getFont(
                                                    'Roboto',
                                                    textStyle: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FontStyle.normal,
                                                    ),
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                              InkWell(
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        MaterialAlertDialog(
                                                      title:
                                                          'Do you really want to delete this project?, you will not be able to get back',
                                                      positiveButtonText:
                                                          'delete',
                                                      negativeButtonText:
                                                          'cancel',
                                                      onPositiveTap: () {
                                                        _flutterProjectCubit
                                                            .deleteProject(
                                                                project);
                                                      },
                                                    ),
                                                  );
                                                },
                                              )
                                            ],
                                          ),
                                        ))
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

class LogoutButton extends StatelessWidget {
  const LogoutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        BlocProvider.of<AuthenticationCubit>(context, listen: false).logout();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout,
              size: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              'Logout',
              style: AppFontStyle.roboto(14,
                  color: Colors.black, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }
}
