import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/extension_util.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/color_assets.dart';
import '../../constant/preference_key.dart';
import '../../cubit/authentication/authentication_cubit.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../main.dart';
import '../../widgets/flutterpilot_logo.dart';
import '../parameter_ui.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'reset_password.dart';

class AuthNavigation extends StatefulWidget {
  const AuthNavigation({Key? key}) : super(key: key);

  @override
  State<AuthNavigation> createState() => _AuthNavigationState();
}

class _AuthNavigationState extends State<AuthNavigation> {
  final _pref = sl<SharedPreferences>();
  ValueNotifier<bool> loginVisible = ValueNotifier(false);
  late AuthenticationCubit _authenticationCubit;

  @override
  void initState() {
    _authenticationCubit = context.read<AuthenticationCubit>();
    super.initState();

    initialize().then((value) {
      loginVisible.value = true;
    });
  }

  Future<void> initialize() async {
    await dataBridge.init();
    await Future.delayed(const Duration(milliseconds: 700));
    await _authenticationCubit.loginWithPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: BlocListener<AuthenticationCubit, AuthenticationState>(
        listener: (context, state) {
          if (state is AuthLoginSuccessState) {
            TextInput.finishAutofillContext();
            if (_pref.containsKey(PrefKey.projectId)) {
              final projectId = _pref.getString(PrefKey.projectId);
              Navigator.pushReplacementNamed(context, '/projects',
                  arguments: [state.userId, projectId]);
            } else {
              Navigator.pushReplacementNamed(context, '/projects',
                  arguments: state.userId);
            }
          }
        },
        child: Material(
          color: theme.background1,
          child: Stack(
            children: [
              const Positioned.fill(
                child: BackgroundNetAnimation(),
              ),
              Center(
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Hero(
                        tag: 'pilot_logo',
                        child: FlutterPilotLogo(),
                      ),
                      20.hBox,
                      AnimatedSize(
                        duration: const Duration(milliseconds: 500),
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: Responsive.isMobile(context) ? null : 400,
                          child: ValueListenableBuilder(
                              valueListenable: loginVisible,
                              child: IntrinsicHeight(
                                child: Container(
                                  width:
                                      Responsive.isMobile(context) ? null : 400,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: ColorAssets.colorD0D5EF),
                                  ),
                                  child: Navigator(
                                    onGenerateRoute: (settings) {
                                      if (settings.name == '/login') {
                                        return getRoute(
                                            (context) => const LoginPage(),
                                            '/login',
                                            anim: false);
                                      } else if (settings.name == '/register') {
                                        return getRoute(
                                            (_) => const RegisterPage(),
                                            '/register',
                                            anim: false);
                                      } else if (settings.name ==
                                          '/reset-password') {
                                        return getRoute(
                                            (context) =>
                                                const ResetPasswordPage(),
                                            '/reset-password',
                                            anim: false);
                                      }
                                      return null;
                                    },
                                    initialRoute: '/login',
                                    restorationScopeId: 'auth',
                                  ),
                                ),
                              ),
                              builder: (context, value, child) {
                                return Visibility(
                                  child: child?.animate().fadeIn() ??
                                      const Offstage(),
                                  replacement: const SizedBox.shrink(),
                                  visible: value,
                                );
                              }),
                        ),
                      ),
                    ],
                  ).animate().saturate(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackgroundNetAnimation extends StatefulWidget {
  const BackgroundNetAnimation({super.key});

  @override
  State<BackgroundNetAnimation> createState() => _BackgroundNetAnimationState();
}

const _points = 30;
List<Offset>? _pointsList;
List<Offset>? _travelledDistances;
List<Offset>? _oldPointsList;

class _BackgroundNetAnimationState extends State<BackgroundNetAnimation>
    with SingleTickerProviderStateMixin {
  final random = Random.secure();
  AnimationController? _controller;
  final List<int> hoverPoints = [];

  final hoverDebounce = Debounce(const Duration(seconds: 2));
  Timer? timer;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _pointsList = null;
    _oldPointsList = null;
    update();
    update();
    if (!(timer?.isActive ?? false)) {
      timer = Timer.periodic(const Duration(seconds: 2), (timer) => update());
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void update() {
    _oldPointsList = _pointsList;
    if (_pointsList == null) {
      final width = MediaQuery.of(context).size.width;
      final height = MediaQuery.of(context).size.height;
      _pointsList = List.generate(_points + 1, (index) {
        return Offset(
            random.nextDouble() * width, random.nextDouble() * height);
      });
      _travelledDistances = List.generate(
        _points,
        (index) => Offset(
            20 * (random.nextDouble() - 0.5), 20 * (random.nextDouble() - 0.5)),
      );
    } else {
      _pointsList = List.generate(
        _points,
        (index) {
          final distance = Offset(
              (-_travelledDistances![index].dx * 0.2) +
                  (20 * cos((random.nextDouble() - 0.5) * 2 * pi)),
              ((-_travelledDistances![index].dy * 0.2) +
                  (20 * sin((random.nextDouble() - 0.5) * 2 * pi))));
          _travelledDistances![index] += distance;
          return _pointsList![index] + distance;
        },
      );
    }

    _controller?.reset();
    _controller?.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (event) {
        if (hoverPoints.length > 5) {
          hoverPoints.removeRange(0, hoverPoints.length ~/ 2);
        }
        for (int i = 0; i < (_pointsList?.length ?? 0); i++) {
          if ((_pointsList![i] - event.position).distanceSquared < 1000) {
            hoverPoints.add(i);
          }
        }
        hoverDebounce.run(() {
          hoverPoints.removeRange(0, hoverPoints.length ~/ 2);
        });
      },
      child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: AuthBackPainter(_pointsList!, _oldPointsList,
                  _controller!.value, hoverPoints),
            );
          }),
    );
  }
}

class AuthBackPainter extends CustomPainter {
  final List<Offset> list;
  final List<Offset>? oldList;
  final List<int> hoverList;
  final double value;

  AuthBackPainter(this.list, this.oldList, this.value, this.hoverList);

  @override
  void paint(Canvas canvas, Size size) {
    if (oldList == null) {
      // canvas.drawPoints(
      //   PointMode.lines,
      //   list,
      //   Paint()
      //     ..style = PaintingStyle.stroke
      //     ..strokeCap = StrokeCap.round
      //     ..strokeWidth = 2
      //     ..color = ColorAssets.colorD0D5EF.withOpacity(0.3),
      // );
    } else {
      final pointList = list
          .asMap()
          .entries
          .map((e) => lerpOffset(oldList![e.key], e.value, value))
          .toList();
      final paint = Paint();
      final paintLine = Paint();
      paintLine.strokeWidth = 0.5;
      paintLine.color = ColorAssets.colorD0D5EF;
      paint.strokeWidth = 8;
      paint.strokeCap = StrokeCap.round;
      final colorLen = Colors.primaries.length;
      final List<bool> hovered = List.filled(pointList.length, false);
      for (final hoverPoint in hoverList) {
        hovered[hoverPoint] = true;
      }
      for (int i = 0; i < pointList.length; i++) {
        paint.color = Colors.primaries[i % colorLen];
        if (i > 0) {
          canvas.drawLine(pointList[i - 1], pointList[i], paintLine);
        }
        if (!hovered[i]) {
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
        } else {
          paint.maskFilter = null;
        }

        canvas.drawPoints(PointMode.points, [pointList[i]], paint);
      }
      // canvas.drawPoints(
      //   PointMode.lines,
      //   pointList,
      //   Paint()
      //     ..style = PaintingStyle.stroke
      //     ..strokeCap = StrokeCap.round
      //     ..strokeWidth = 2
      //     ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 12)
      //     ..color = ColorAssets.colorD0D5EF.withOpacity(0.3),
      // );
      // canvas.drawPoints(
      //   PointMode.lines,
      //   pointList,
      //   Paint()
      //     ..style = PaintingStyle.stroke
      //     ..strokeCap = StrokeCap.round
      //     ..strokeWidth = 2
      //     ..color = ColorAssets.colorD0D5EF.withOpacity(0.3),
      // );
    }
  }

  Offset lerpOffset(Offset o1, Offset o2, double value) => Offset(
      lerpDouble(o1.dx, o2.dx, value)!, lerpDouble(o1.dy, o2.dy, value)!);

  @override
  bool shouldRepaint(AuthBackPainter oldDelegate) => true;
}
