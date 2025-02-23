import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../constant/image_asset.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../authentication/auth_navigation.dart';
import '../navigation/animated_dialog.dart';

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
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthLoginSuccessState) {
          AnimatedDialog.hide(context).then((value) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              Navigator.pushNamed(context, '/projects',
                  arguments: state.userId);
            });
          });
        }
      },
      child: Scaffold(
        backgroundColor: ColorAssets.white,
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
                  style: AppFontStyle.lato(18,
                      color: ColorAssets.darkGrey, fontWeight: FontWeight.bold),
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
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter path';
                        } else if (!value!.contains('_')) {
                          return 'Wrong Path';
                        } else if (value.contains(' ')) {
                          return 'Please enter path without spaces';
                        }
                        return null;
                      },
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
                            // Navigator.pushNamed(context, '/run', arguments:[widget]);
                          }
                        },
                        enableFeedback: !value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: value
                                ? Colors.grey.shade400
                                : ColorAssets.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: ColorAssets.white,
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
                  color: ColorAssets.lightGrey,
                  thickness: 2,
                ),
                const SizedBox(
                  height: 50,
                ),
                Text(
                  'Start working on your project now!',
                  style: AppFontStyle.lato(
                    18,
                    color: ColorAssets.darkGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                FilledButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.resolveWith(
                        (states) => RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.hovered)
                          ? ColorAssets.theme.withOpacity(0.8)
                          : ColorAssets.theme,
                    ),
                    padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  ),
                  onPressed: () {
                    if (dataBridge.isLoggedIn()) {
                      Navigator.pushNamed(context, '/projects',
                          arguments: dataBridge.currentUserId);
                    } else {
                      openAuthDialog(context, (context, userId) {});
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        Images.logo,
                        width: 30,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Get Started with FlutterPilot',
                        style: AppFontStyle.lato(18,
                            color: Colors.white, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  getPage(child, String name) {
    return MaterialPage(child: child, name: name);
  }
}

void openAuthDialog(
    BuildContext context, void Function(BuildContext, int) onSuccess,
    {bool dismissible = true}) {
  if (Responsive.isMobile(context)) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthNavigation(),
      ),
    );
  } else {
    AnimatedDialog.show(
      context,
      const AuthNavigation(),
      barrierDismissible: dismissible,
    );
  }
}

class CommonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final bool border;
  final FormFieldValidator? validator;
  final bool enabled;
  final int? maxLines;
  final double? fontSize;
  final String? initial;

  const CommonTextField(
      {Key? key,
      this.maxLines,
      this.initial,
      this.enabled = true,
      this.border = false,
      this.controller,
      this.hintText,
      this.onChanged,
      this.validator,
      this.fontSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: ColorAssets.theme,
      enabled: enabled,
      initialValue: initial,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
      controller: controller,
      style: AppFontStyle.lato(fontSize ?? (border ? 13 : 18),
          color: ColorAssets.darkGrey,
          fontWeight: border ? FontWeight.normal : FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        border: border
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: ColorAssets.lightGrey))
            : InputBorder.none,
        focusColor: ColorAssets.theme,
        focusedBorder: border
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: ColorAssets.theme, width: 1.5))
            : InputBorder.none,
        enabledBorder: border
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: ColorAssets.grey))
            : InputBorder.none,
        hintStyle: AppFontStyle.lato(fontSize ?? (border ? 13 : 18),
            color: ColorAssets.grey),
        errorStyle: AppFontStyle.lato(fontSize ?? 13,
            color: ColorAssets.red, fontWeight: FontWeight.normal),
        contentPadding: border
            ? EdgeInsets.symmetric(
                horizontal: 8, vertical: (maxLines ?? 1) > 1 ? 8 : 0)
            : const EdgeInsets.all(8),
      ),
    );
  }
}
