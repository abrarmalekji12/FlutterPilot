import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/app_loader.dart';
import '../firestore/firestore_bridge.dart';
import '../models/project_model.dart';
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
  List<FlutterProject> _flutterProjects = [];
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flutterProjectCubit = FlutterProjectCubit(widget.userId);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
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
          child: BlocListener<FlutterProjectCubit, FlutterProjectState>(
            bloc: _flutterProjectCubit,
            listener: (context, state) {
              switch (state.runtimeType) {
                case FlutterProjectLoadingState:
                  AppLoader.show(context);
                  break;
                case FlutterProjectsLoadedState:
                  AppLoader.hide();
                  _flutterProjects =
                      (state as FlutterProjectsLoadedState).flutterProjectList;
                  setState(() {});
                  break;
                case FlutterProjectLoadedState:
                  _flutterProjects
                      .add((state as FlutterProjectLoadedState).flutterProject);
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
                Text(
                  'Select a project to get started',
                  style: GoogleFonts.getFont(
                    'Roboto',
                    textStyle: const TextStyle(
                      fontSize: 25,
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
                TextField(
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
                        color: Color(0xff000000),
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
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                if (_textEditingController.text.length > 3) {
                                  final name = _textEditingController.text;
                                  _flutterProjectCubit
                                      .createNewProject(name)
                                      .then((value) {
                                    _textEditingController.text = '';

                                    setState(() {

                                    });
                                    Get.to(
                                        () => HomePage(
                                              projectName: name,
                                              userId: widget.userId,
                                            ),
                                        routeName: 'projects/$name');
                                  });
                                }
                              },
                              child: Container(
                                  padding: const EdgeInsets.all(20),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffffffff),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xff171717),
                                      width: 3,
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      const Icon(
                                        Icons.add,
                                        size: 35,
                                        color: Color(0xff000000),
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
                                            color: Color(0xff000000),
                                            fontWeight: FontWeight.w500,
                                            fontStyle: FontStyle.normal,
                                          ),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  )),
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
                              fontSize: 20,
                              color: Color(0xff747474),
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
                              children: _flutterProjects
                                  .map((project) => Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10, bottom: 10),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Get.to(
                                                () => HomePage(
                                                      projectName: project.name,
                                                      userId: widget.userId,
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
                                                fontWeight: FontWeight.w500,
                                                fontStyle: FontStyle.normal,
                                              ),
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
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
          )),
    );
  }
}
