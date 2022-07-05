import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/common_methods.dart';
import '../../common/extension_util.dart';
import '../../common/app_loader.dart';
import '../../common/password_box.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../cubit/flutter_project/flutter_project_cubit.dart';
import '../../firestore/firestore_bridge.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

late double dw;
late double dh;

const double tabletWidthLimit = 1200;
const double phoneWidthLimit = 900;

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final AuthenticationCubit _authenticationCubit;
  final TextEditingController _userNameController = TextEditingController(),
      _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authenticationCubit =
        BlocProvider.of<AuthenticationCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _userNameController.text = _authenticationCubit.authViewModel.userName;
      _passwordController.text = _authenticationCubit.authViewModel.password;
      AppLoader.show(context);
      FireBridge.init().then((value) {
        AppLoader.hide();
        _authenticationCubit.loginWithPreferences();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    dw = MediaQuery.of(context).size.width;
    dh = MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthLoadingState) {
          AppLoader.show(context);
        } else if (state is AuthSuccessState) {
          AppLoader.hide();
          context.read<FlutterProjectCubit>().setUserId = state.userId;
        } else if (state is AuthFailedState) {
          AppLoader.hide();
          showToast(state.message, error: true);
        } else if (state is AuthErrorState) {
          AppLoader.hide();
          showToast(state.message, error: true);
        }
      },
      child: AuthenticationPage(
          formKey: _formKey,
          widget: () => SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                                text: 'If you are new/',
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
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacementNamed(
                                        context, '/register');
                                  },
                                text: ' Create New',
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
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.getFont(
                            'Roboto',
                            textStyle: const TextStyle(
                              fontSize: 19,
                              color: Color(0xffffffff),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          onChanged: (value) {
                            _authenticationCubit.authViewModel.userName = value;
                          },
                          onFieldSubmitted: (value) {
                            FocusScope.of(context).nextFocus();
                          },
                          onEditingComplete: () {
                            FocusScope.of(context).nextFocus();
                          },
                          validator: (value) {
                            return (!(value?.isValidEmail() ?? false))
                                ? 'Invalid email'
                                : null;
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
                                ),
                              ),
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
                                fontSize: 15,
                                color: Color(0xff9c9da2),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: ' Reset Now',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacementNamed(
                                    context, '/reset-password');
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
                    const SizedBox(
                      height: 40,
                    ),
                    InkWell(
                      onTap: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _authenticationCubit.login(
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
                          'Log in',
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
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom,
                    ),
                  ],
                ),
              )),
    );
  }
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

class AuthenticationPage extends StatefulWidget {
  final Widget Function() widget;
  final GlobalKey<FormState> formKey;

  const AuthenticationPage(
      {Key? key, required this.widget, required this.formKey})
      : super(key: key);

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(30),
      child: Form(
        key: widget.formKey,
        child: widget.widget.call(),
      ),
    );
  }
}
