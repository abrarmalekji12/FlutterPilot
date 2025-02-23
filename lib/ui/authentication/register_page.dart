import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/app_button.dart';
import '../../common/common_methods.dart';
import '../../common/extension_util.dart';
import '../../common/password_box.dart';
import '../../common/responsive/responsive_dimens.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../cubit/user_details/user_details_cubit.dart';
import '../../injector.dart';
import '../../user_session.dart';
import '../../widgets/loading/button_loading.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _userNameController = TextEditingController(),
      _passwordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  final UserSession _userSession = sl();

  late final AuthenticationCubit _authenticationCubit;
  final GlobalKey<FormState> _formKey = GlobalKey();

  late double dw;
  late double dh;

  @override
  void initState() {
    super.initState();
    _authenticationCubit = BlocProvider.of<AuthenticationCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _userSession.user.email = '';
      _userSession.user.password = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    dw = MediaQuery.of(context).size.width;
    dh = MediaQuery.of(context).size.height;
    final fontSize = res(context, 18.sp, 14.sp, 18.sp);

    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthLoginSuccessState) {
          context.read<UserDetailsCubit>().setUserId = state.userId;
        } else if (state is AuthFailedState) {
          showToast(state.message, error: true);
        } else if (state is AuthErrorState) {
          showToast(state.message, error: true);
        }
      },
      child: AuthenticationPage(
        widget: () => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
              padding: Responsive.isDesktop(context)
                  ? const EdgeInsets.all(30)
                  : const EdgeInsets.all(20),
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'Register',
                    style: AppFontStyle.headerStyle(),
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
                          style: AppFontStyle.lato(
                            14,
                            color: const Color(0xff9c9da2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: ' Login',
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                          style: AppFontStyle.lato(
                            16,
                            color: const Color(0xff1a1b26),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xfff5f5f5),
                        borderRadius: BorderRadius.circular(10),
                        shape: BoxShape.rectangle,
                      ),
                      child: TextFormField(
                        controller: _userNameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: [AutofillHints.email],
                        style: AppFontStyle.lato(
                          fontSize,
                          color: ColorAssets.darkGrey,
                          fontWeight: FontWeight.w400,
                        ),
                        validator: (value) {
                          return (!(value?.isValidEmail() ?? false))
                              ? 'Invalid email'
                              : null;
                        },
                        onChanged: (value) {
                          _userSession.user.email = value;
                        },
                        readOnly: false,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          labelText: 'Your Email',
                          labelStyle: AppFontStyle.lato(
                            fontSize,
                            color: const Color(0xffababa9),
                            fontWeight: FontWeight.w500,
                          ),
                          helperStyle: AppFontStyle.lato(
                            13,
                            color: Colors.black,
                          ),
                          hintStyle: AppFontStyle.lato(
                            13,
                            color: Colors.black,
                          ),
                          errorStyle: AppFontStyle.lato(
                            13,
                            color: Colors.red,
                          ),
                          border: InputBorder.none,
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(
                              right: 10,
                            ),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                color: Color(0xff3b403f),
                              ),
                            ),
                          ),
                          iconColor: Colors.white,
                          prefixStyle: AppFontStyle.lato(
                            13,
                            color: Colors.black,
                          ),
                          suffixStyle: AppFontStyle.lato(
                            13,
                            color: Colors.black,
                          ),
                          fillColor: const Color(0xfffdce84),
                          enabled: true,
                        ),
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xfff5f5f5),
                      borderRadius: BorderRadius.circular(10),
                      shape: BoxShape.rectangle,
                    ),
                    child: PasswordBox(
                      controller: _passwordController,
                      onChanged: (value) {
                        _userSession.user.password = value;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xfff5f5f5),
                      borderRadius: BorderRadius.circular(10),
                      shape: BoxShape.rectangle,
                    ),
                    child: PasswordBox(
                      text: 'Confirm Password',
                      validator: (value) {
                        return value != _userSession.user.password
                            ? 'Please enter same password'
                            : null;
                      },
                      controller: _confirmPasswordController,
                      onChanged: (value) {
                        _userSession.user.confirmPassword = value;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                      height: 50,
                      child:
                          BlocBuilder<AuthenticationCubit, AuthenticationState>(
                        buildWhen: (_, state) =>
                            state is AuthLoadingState ||
                            state is AuthErrorState ||
                            state is AuthFailedState,
                        builder: (context, state) {
                          if (state is AuthLoadingState) {
                            return const ButtonLoadingWidget();
                          }
                          return AppButton(
                            title: 'Register Now',
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _authenticationCubit
                                    .register(_userSession.user);
                              }
                            },
                          );
                        },
                      )),
                ],
              )),
        ),
        formKey: _formKey,
      ),
    );
  }
}
