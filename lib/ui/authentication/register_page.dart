import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/extension_util.dart';
import '../../common/app_loader.dart';
import '../../common/password_box.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../cubit/flutter_project/flutter_project_cubit.dart';
import '../../models/actions/action_model.dart';
import '../project_selection_page.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const double tabletWidthLimit = 1200;
  static const double phoneWidthLimit = 900;
  static const double pd = 10;
  final TextEditingController _userNameController = TextEditingController(),
      _passwordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  late final AuthenticationCubit _authenticationCubit;
  final GlobalKey<FormState> _formKey = GlobalKey();

  late double dw;
  late double dh;

  @override
  void initState() {
    super.initState();
    _authenticationCubit =
        BlocProvider.of<AuthenticationCubit>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _authenticationCubit.authViewModel.userName = '';
      _authenticationCubit.authViewModel.password = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    dw = MediaQuery.of(context).size.width;
    dh = MediaQuery.of(context).size.height;

    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthLoadingState) {
          AppLoader.show(context);
        } else if (state is AuthSuccessState) {
          AppLoader.hide();
          context.read<FlutterProjectCubit>().setUserId = state.userId;

        } else if (state is AuthFailedState) {
          AppLoader.hide();
          Fluttertoast.showToast(msg: state.message, timeInSecForIosWeb: 3);
        }
      },
      child: AuthenticationPage(
        widget: ()=>SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Image.asset(
                  'assets/icons/half_circle.png',
                  width: 30,
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(
                  height: 30,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hey,\nLogin Now.',
                      style: GoogleFonts.getFont(
                        'Lato',
                        textStyle: const TextStyle(
                          fontSize: 22,
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
                            text: 'Already having account? /',
                            style: GoogleFonts.getFont(
                              'Roboto',
                              textStyle: const TextStyle(
                                fontSize: 15,
                                color: Color(0xff9c9da2),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: ' Login',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {

                                Navigator.pushReplacementNamed(context,'/login');
                              },
                            style: GoogleFonts.getFont(
                              'Lato',
                              textStyle: const TextStyle(
                                fontSize: 17,
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
                ),
                const SizedBox(
                  height: 30,
                ),
                Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xfffdce84),
                      borderRadius: BorderRadius.circular(10),
                      shape: BoxShape.rectangle,
                    ),
                    child: TextFormField(
                      controller: _userNameController,
                      style: GoogleFonts.getFont(
                        'Roboto',
                        textStyle: const TextStyle(
                          fontSize: 19,
                          color: Color(0xffffffff),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      validator: (value) {
                        return (!(value?.isValidEmail() ?? false))
                            ? 'Invalid email'
                            : null;
                      },
                      onChanged: (value) {
                        _authenticationCubit.authViewModel.userName = value;
                      },
                      readOnly: false,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        labelText: 'Your Email',
                        labelStyle: GoogleFonts.getFont(
                          'Roboto',
                          textStyle: const TextStyle(
                            fontSize: 19,
                            color: Color(0xffffffff),
                            fontWeight: FontWeight.w600,
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
                        border: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide.none,
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
                                backgroundColor: Color(0xffffffff),
                                foregroundColor: Color(0xffffffff),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xff3b403f),
                                ))),
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
                        enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: const Color(0xfffdce84),
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
                    borderRadius: BorderRadius.circular(10),
                    shape: BoxShape.rectangle,
                  ),
                  child: PasswordBox(
                    controller: _passwordController,
                    onChanged: (value) {
                      _authenticationCubit.authViewModel.password = value;
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f5f5),
                    borderRadius: BorderRadius.circular(10),
                    shape: BoxShape.rectangle,
                  ),
                  child: PasswordBox(
                    text: 'Confirm Password',
                    validator: (value) {
                      return value !=
                              _authenticationCubit.authViewModel.password
                          ? 'Please enter same password'
                          : null;
                    },
                    controller: _confirmPasswordController,
                    onChanged: (value) {
                      _authenticationCubit.authViewModel.confirmPassword =
                          value;
                    },
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                InkWell(
                  onTap: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _authenticationCubit.register(
                          _authenticationCubit.authViewModel.userName,
                          _authenticationCubit.authViewModel.password);
                    }
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffb12341),
                      borderRadius: BorderRadius.circular(10),
                      shape: BoxShape.rectangle,
                    ),
                    child: Text(
                      'Register Now',
                      style: GoogleFonts.getFont(
                        'Roboto',
                        textStyle: const TextStyle(
                          fontSize: 16,
                          color: Color(0xffffffff),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Center(
                    child: Text(
                  'Skip Now',
                  style: GoogleFonts.getFont(
                    'ABeeZee',
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff464646),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  textAlign: TextAlign.left,
                )),
              ],
            )),
        formKey: _formKey,
      ),
    );
  }

  double res(double large, double medium, [double? small]) {
    if (dw > tabletWidthLimit) {
      return large;
    } else if (dw > phoneWidthLimit || small == null) {
      return medium;
    } else {
      return small;
    }
  }
}
