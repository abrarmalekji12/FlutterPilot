import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/app_loader.dart';
import '../../common/button_loading_widget.dart';
import '../../common/common_methods.dart';
import '../../common/extension_util.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../injector.dart';
import '../../user_session.dart';
import '../../widgets/button/app_button.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const double tabletWidthLimit = 1200;
  static const double phoneWidthLimit = 900;
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final AuthenticationCubit _authenticationCubit;
  final TextEditingController _userNameController = TextEditingController();
  final UserSession _userSession = sl();

  late double dw;
  late double dh;

  @override
  void initState() {
    super.initState();
    _authenticationCubit = BlocProvider.of<AuthenticationCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _userNameController.text = _userSession.user.email;
    });
  }

  @override
  Widget build(BuildContext context) {
    dw = MediaQuery.of(context).size.width;
    dh = MediaQuery.of(context).size.height;

    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthFailedState) {
          showConfirmDialog(
              title: 'Error!',
              subtitle: state.message,
              context: context,
              positive: 'ok',
              onPositiveTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              });
        } else if (state is AuthResetPasswordSuccessState) {
          showConfirmDialog(
              title: 'Reset Password',
              subtitle:
                  'Check your mail for instructions on resetting your password',
              context: context,
              positive: 'ok',
              dismissible: false,
              onPositiveTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              });
        } else if (state is AuthErrorState) {
          AppLoader.hide(context);

          showToast(state.message);
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
                    'Reset Password',
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
                          text: 'Back to/',
                          style: AppFontStyle.lato(
                            14,
                            color: const Color(0xff9c9da2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                          text: ' Login',
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
                        style: AppFontStyle.lato(
                          18,
                          color: ColorAssets.darkGrey,
                          fontWeight: FontWeight.w400,
                        ),
                        onChanged: (value) {
                          _userSession.user.email = value;
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
                          labelStyle: AppFontStyle.lato(
                            18,
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
                            color: Colors.white,
                          ),
                          suffixStyle: AppFontStyle.lato(
                            13,
                            color: Colors.black,
                          ),
                          fillColor: const Color(0xfffdce84),
                        ),
                      )),
                  const SizedBox(
                    height: 40,
                  ),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child:
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                      buildWhen: (_, state) =>
                          state is AuthLoadingState ||
                          state is AuthErrorState ||
                          state is AuthFailedState ||
                          state is AuthResetPasswordSuccessState,
                      builder: (context, state) {
                        if (state is AuthLoadingState) {
                          return const ButtonLoadingWidget();
                        }
                        return AppButton(
                            text: 'Submit',
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _authenticationCubit
                                    .resetPassword(_userSession.user.email);
                              }
                            });
                      },
                    ),
                  ),
                ],
              )),
        ),
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
