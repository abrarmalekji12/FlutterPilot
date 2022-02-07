// copy all the images to assets/images/ folder
//
// TODO Dependencies (add into pubspec.yaml)
// google_fonts: ^2.2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/responsive/responsive_widget.dart';
import '../../common/app_loader.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../firestore/firestore_bridge.dart';
import '../project_selection_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const LoginPage());
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late double dw;
  late double dh;
  final AuthenticationCubit _authenticationCubit = AuthenticationCubit();
  final TextEditingController _userNameController = TextEditingController(),
      _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _userNameController.text = 'Abrar';
      _passwordController.text = 'passwor';
      AppLoader.show(context);
      FireBridge.init().then((value) {
        AppLoader.hide();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    dw = MediaQuery.of(context).size.width;
    dh = MediaQuery.of(context).size.height;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (key) {
        // if (key is RawKeyDownEvent &&
        //     key.physicalKey == PhysicalKeyboardKey.enter) {
        //   if (_userNameController.text.isNotEmpty &&
        //       _passwordController.text.isNotEmpty) {
        //     _authenticationCubit.login(
        //         _userNameController.text, _passwordController.text);
        //   }
        // }
      },
      child: BlocProvider<AuthenticationCubit>(
        create: (context) => _authenticationCubit,
        child: BlocListener<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthLoadingState) {
              AppLoader.show(context);
            } else if (state is AuthSuccessState) {
              AppLoader.hide();
              Get.off(
                  () => ProjectSelectionPage(
                        userId: state.userId,
                      ),
                  routeName: 'projects');
            } else if (state is AuthFailedState) {
              AppLoader.hide();
              Fluttertoast.showToast(msg: state.message, timeInSecForIosWeb: 3);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xffffffff),
            resizeToAvoidBottomInset: false,
            body: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xfffcdbe6),
                  shape: BoxShape.rectangle,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Image.asset(
                        'assets/icons/background_visual_builder.png',
                        height: dh,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                            width: ResponsiveWidget.isLargeScreen(context)?dw* 0.3:dw,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xffffffff),
                              shape: BoxShape.rectangle,
                            ),
                            child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Image.asset(
                                          'assets/icons/half_circle.png',
                                          width: 50,
                                          fit: BoxFit.fitWidth,
                                        ),
                                        const SizedBox(
                                          height: 60,
                                        ),
                                        const LoginMessage(),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        Container(
                                            height: 60,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xfffdce84),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              shape: BoxShape.rectangle,
                                            ),
                                            child: TextField(
                                              controller: _userNameController,
                                              style: GoogleFonts.getFont(
                                                'Roboto',
                                                textStyle: const TextStyle(
                                                  fontSize: 18,
                                                  color: Color(0xff000000),
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.visiblePassword,
                                              readOnly: false,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 5,
                                                ),
                                                labelText: 'User Name',
                                                labelStyle: GoogleFonts.getFont(
                                                  'Roboto',
                                                  textStyle: const TextStyle(
                                                    fontSize: 19,
                                                    color: Color(0xff333034),
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                                helperStyle:
                                                    GoogleFonts.getFont(
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
                                                suffixIcon: const Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 0,
                                                      left: 0,
                                                      bottom: 0,
                                                      right: 10,
                                                    ),
                                                    child: CircleAvatar(
                                                        radius: 10,
                                                        backgroundColor:
                                                            Color(0xffffffff),
                                                        foregroundColor:
                                                            Color(0xffffffff),
                                                        child: Icon(
                                                          Icons.person,
                                                          color:
                                                              Color(0xff3b403f),
                                                        ))),
                                                iconColor:
                                                    const Color(0xffffffff),
                                                prefixText: '',
                                                prefixStyle:
                                                    GoogleFonts.getFont(
                                                  'ABeeZee',
                                                  textStyle: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xff000000),
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                                suffixText: '',
                                                suffixStyle:
                                                    GoogleFonts.getFont(
                                                  'ABeeZee',
                                                  textStyle: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xff000000),
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                  borderSide: BorderSide.none,
                                                ),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                  borderSide: BorderSide.none,
                                                ),
                                                fillColor:
                                                    const Color(0xfffdce84),
                                                enabled: true,
                                              ),
                                            )),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Container(
                                            height: 60,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xfff5f5f5),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              shape: BoxShape.rectangle,
                                            ),
                                            child: TextField(
                                              controller: _passwordController,
                                              obscureText: true,
                                              style: GoogleFonts.getFont(
                                                'Roboto',
                                                textStyle: const TextStyle(
                                                  fontSize: 18,
                                                  color: Color(0xff000000),
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: FontStyle.normal,
                                                ),
                                              ),
                                              readOnly: false,
                                              onSubmitted: (value){
                                                // if (key is RawKeyDownEvent &&
                                                //     key.physicalKey == PhysicalKeyboardKey.enter) {
                                                  if (_userNameController.text.isNotEmpty &&
                                                      _passwordController.text.isNotEmpty) {
                                                    _authenticationCubit.login(
                                                        _userNameController.text, _passwordController.text);
                                                  // }
                                                }
                                              },
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 5,
                                                ),
                                                labelText: 'Password',
                                                labelStyle: GoogleFonts.getFont(
                                                  'Roboto',
                                                  textStyle: const TextStyle(
                                                    fontSize: 19,
                                                    color: Color(0xffababa9),
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                                helperStyle:
                                                    GoogleFonts.getFont(
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
                                                border: UnderlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                  borderSide: BorderSide.none,
                                                ),
                                                iconColor:
                                                    const Color(0xffffffff),
                                                prefixText: '',
                                                prefixStyle:
                                                    GoogleFonts.getFont(
                                                  'ABeeZee',
                                                  textStyle: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xff000000),
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                                suffixText: '',
                                                suffixStyle:
                                                    GoogleFonts.getFont(
                                                  'ABeeZee',
                                                  textStyle: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xff000000),
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                  borderSide: BorderSide.none,
                                                ),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xffffffff),
                                                    width: 2,
                                                  ),
                                                ),
                                                fillColor:
                                                    const Color(0xfffdce84),
                                              ),
                                            )),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Forgot Password?',
                                                style: GoogleFonts.getFont(
                                                  'Roboto',
                                                  textStyle: const TextStyle(
                                                    fontSize: 19,
                                                    color: Color(0xff9c9da2),
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' Reset Now',
                                                style: GoogleFonts.getFont(
                                                  'Lato',
                                                  textStyle: const TextStyle(
                                                    fontSize: 20,
                                                    color: Color(0xff1a1b26),
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.normal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 40,
                                        ),
                                        LoginWidget(
                                            userNameController:
                                                _userNameController,
                                            passwordController:
                                                _passwordController,
                                            authenticationCubit:
                                                _authenticationCubit),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        Center(
                                            child: Text(
                                          'Skip Now',
                                          style: GoogleFonts.getFont(
                                            'ABeeZee',
                                            textStyle: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xff9c9da1),
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.normal,
                                            ),
                                          ),
                                          textAlign: TextAlign.left,
                                        )),
                                      ],
                                    ))))),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}

class LoginWidget extends StatelessWidget {
  const LoginWidget({
    Key? key,
    required TextEditingController userNameController,
    required TextEditingController passwordController,
    required AuthenticationCubit authenticationCubit,
  })  : _userNameController = userNameController,
        _passwordController = passwordController,
        _authenticationCubit = authenticationCubit,
        super(key: key);

  final TextEditingController _userNameController;
  final TextEditingController _passwordController;
  final AuthenticationCubit _authenticationCubit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (_userNameController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty) {
          _authenticationCubit.login(
              _userNameController.text, _passwordController.text);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffb12341),
            borderRadius: BorderRadius.circular(10),
            shape: BoxShape.rectangle,
          ),
          child: Text(
            'Log in',
            style: GoogleFonts.getFont(
              'Roboto',
              textStyle: const TextStyle(
                fontSize: 18,
                color: Color(0xffffffff),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
              ),
            ),
            textAlign: TextAlign.left,
          )),
    );
  }
}

class LoginMessage extends StatelessWidget {
  const LoginMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hey,\nLogin Now.',
          style: GoogleFonts.getFont(
            'Lato',
            textStyle: const TextStyle(
              fontSize: 29,
              color: Color(0xff000000),
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.normal,
            ),
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 20,
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'If you are new/',
                style: GoogleFonts.getFont(
                  'Roboto',
                  textStyle: const TextStyle(
                    fontSize: 19,
                    color: Color(0xff9c9da2),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
              TextSpan(
                text: ' Create New',
                style: GoogleFonts.getFont(
                  'Lato',
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Color(0xff1a1b26),
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
