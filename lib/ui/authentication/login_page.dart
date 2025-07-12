import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/common_methods.dart';
import '../../common/extension_util.dart';
import '../../common/password_box.dart';
import '../../common/responsive/responsive_dimens.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../injector.dart';
import '../../user_session.dart';
import '../../widgets/button/app_button.dart';
import '../../widgets/loading/button_loading.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

const double tabletWidthLimit = 1200;
const double phoneWidthLimit = 900;

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  late final AuthenticationCubit _authenticationCubit;
  final TextEditingController _userNameController = TextEditingController(),
      _passwordController = TextEditingController();
  final UserSession _userSession = sl();

  @override
  void initState() {
    super.initState();
    _authenticationCubit = context.read<AuthenticationCubit>();
    _authenticationCubit.initial();
    _userNameController.text = _userSession.user.email;
    _passwordController.text = _userSession.user.password;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = res(context, 18.sp, 14.sp, 18.sp);

    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthFailedState) {
          showConfirmDialog(
            title: 'Error',
            subtitle: state.message,
            context: context,
            positive: i10n.ok,
          );
          // showToast(state.message, error: true);
        } else if (state is AuthErrorState) {
          // showToast(state.message, error: true);
          showConfirmDialog(
            title: 'Error',
            subtitle: state.message,
            context: context,
            positive: i10n.ok,
          );
        }
      },
      child: AuthenticationPage(
          formKey: _formKey,
          widget: () => FocusScope(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.background1,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    padding: Responsive.isDesktop(context)
                        ? const EdgeInsets.all(30)
                        : const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: kDebugMode
                                  ? () {
                                      _userNameController.text =
                                          'abrar.malekji@mailinator.com';
                                      _passwordController.text = 'abrar123';
                                    }
                                  : null,
                              child: Text(
                                'Login',
                                style: AppFontStyle.headerStyle(),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'If you are new/',
                                    style: AppFontStyle.lato(
                                      14,
                                      color: const Color(0xff9c9da2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushReplacementNamed(
                                            context, '/register');
                                      },
                                    text: ' Create New',
                                    style: AppFontStyle.lato(
                                      16,
                                      color: const Color(0xff1a1b26),
                                      fontWeight: FontWeight.w600,
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
                            decoration: BoxDecoration(
                              color: const Color(0xfff5f5f5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: TextFormField(
                              controller: _userNameController,
                              textInputAction: TextInputAction.next,
                              style: AppFontStyle.lato(
                                fontSize,
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
                              autofillHints: [AutofillHints.email],
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
                                  fontWeight: FontWeight.w400,
                                ),
                                hintStyle: AppFontStyle.lato(
                                  13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
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
                                    backgroundColor: ColorAssets.white,
                                    foregroundColor: Color(0xffffffff),
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
                                  fontWeight: FontWeight.w400,
                                ),
                                suffixStyle: AppFontStyle.lato(
                                  13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
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
                          height: 30,
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Forgot Password?',
                                style: AppFontStyle.lato(
                                  14,
                                  color: const Color(0xff9c9da2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' Reset Now',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacementNamed(
                                        context, '/reset-password');
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
                          height: 40,
                        ),
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: BlocBuilder<AuthenticationCubit,
                              AuthenticationState>(
                            buildWhen: (_, state) =>
                                state is AuthLoadingState ||
                                state is AuthErrorState ||
                                state is AuthFailedState,
                            builder: (context, state) {
                              if (state is AuthLoadingState) {
                                return const ButtonLoadingWidget();
                              }
                              return AppButton(
                                  text: 'Log In',
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      _authenticationCubit.login(
                                          _userSession.user.email,
                                          _userSession.user.password);
                                    }
                                  });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
    );
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
    return Center(
      child: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: widget.widget.call(),
        ),
      ),
    );
  }
}
