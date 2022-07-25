import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/app_button.dart';
import '../../constant/app_colors.dart';
import '../../constant/font_style.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../cubit/component_operation/component_operation_cubit.dart';
import '../../main.dart';
import '../../models/project_model.dart';
import '../project_setting_page.dart';
import '../authentication/login.dart';
import '../authentication/register_page.dart';
import '../authentication/reset_password.dart';
import '../project_selection_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ValueNotifier<bool> _notifier = ValueNotifier(false);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   showDialog(context: context, builder: (_){
    //     ComponentOperationCubit.currentFlutterProject=FlutterProject('abrarr', 1, 'fsdafs');
    //     return ProjectSettingsPage(componentOperationCubit: ComponentOperationCubit(),);
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter Path To Run App',
                style: AppFontStyle.roboto(18,
                    color: AppColors.darkGrey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30,
              ),
              Form(
                key: _formKey,
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    boxShadow: kElevationToShadow[2],
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: CommonTextField(
                    hintText: 'Enter path',
                    onChanged: (value) {
                      _notifier.value = value.isEmpty;
                    },
                    controller: _controller,
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              ValueListenableBuilder(
                  valueListenable: _notifier,
                  builder: (context, bool value, _) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pushNamed(context, '/run',
                              arguments: RunKey.decrypt(_controller.text));
                        }
                      },
                      enableFeedback: !value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: value ? Colors.grey.shade400 : AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.white,
                          size: 30,
                        ),
                        width: 50,
                        height: 50,
                      ),
                    );
                  }),
              const SizedBox(
                height: 50,
              ),
              const Divider(
                color: AppColors.lightGrey,
                thickness: 2,
              ),
              const SizedBox(
                height: 50,
              ),
              Text(
                'Start working on your project now!',
                style: AppFontStyle.roboto(
                  18,
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  openAuthDialog(context, (userId) {
                    Navigator.pushNamed(context, '/projects',
                        arguments: userId);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.theme,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/fvb_logo_2.png',
                        width: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Text(
                        'Open Builder',
                        style: AppFontStyle.roboto(18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  getPage(child, String name) {
    return MaterialPage(child: child, name: name);
  }
}

void openAuthDialog(BuildContext context, void Function(int) onSuccess) {
  showDialog(
    context: context,
    builder: (_) => Align(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 400,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: BlocListener<AuthenticationCubit, AuthenticationState>(
            listener: (context, state) {
              if (state is AuthSuccessState && state.userId != -1) {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {

                  onSuccess(state.userId);
                });
              }
            },
            child: Navigator(
              onGenerateRoute: (settings) {
                if (settings.name == '/login') {
                  return getRoute((context) => const LoginPage(), null,
                      anim: false);
                } else if (settings.name == '/register') {
                  return getRoute((_) => const RegisterPage(), null,
                      anim: false);
                } else if (settings.name == '/reset-password') {
                  return getRoute((context) => const ResetPasswordPage(), null,
                      anim: false);
                }
              },
              initialRoute: '/login',
              restorationScopeId: 'auth',
            ),
          ),
        ),
      ),
    ),
  );
}

class CommonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String) onChanged;

  const CommonTextField(
      {Key? key,
      required this.controller,
      required this.hintText,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter path';
        } else if (!value!.contains('_')) {
          return 'Wrong Path';
        } else if (value.contains(' ')) {
          return 'Please enter path without spaces';
        } else if (RunKey.decrypt(value) == null) {
          return 'Wrong Path';
        }
        return null;
      },
      onChanged: onChanged,
      controller: controller,
      style: AppFontStyle.roboto(18,
          color: AppColors.darkGrey, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        hintStyle:
            AppFontStyle.roboto(18, color: AppColors.darkGrey.withOpacity(0.4)),
        errorStyle: AppFontStyle.roboto(14,
            color: AppColors.red, fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.all(10),
      ),
    );
  }
}
