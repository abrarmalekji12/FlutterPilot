import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';

import '../common/extension_util.dart';
import '../widgets/button/filled_button.dart';
import '../widgets/button/outlined_button.dart';
import 'navigation/animated_dialog.dart';

class LocalBuildGenerator extends StatefulWidget {
  final String path;

  const LocalBuildGenerator({super.key, required this.path});

  @override
  State<LocalBuildGenerator> createState() => _LocalBuildGeneratorState();
}

class _LocalBuildGeneratorState extends State<LocalBuildGenerator> {
  final controller = StreamController<List<int>>();

  final scrollController = ScrollController();
  final List<String> lines = [];
  int step = 0;
  late Shell shell;

  @override
  void initState() {
    shell = Shell(stdout: controller, stderr: controller);
    shell = shell.cd(widget.path);
    runScripts();
    controller.stream.listen(_listen);
    super.initState();
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(20),
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Console',
              style: AppFontStyle.titleStyle(),
            ),
            30.hBox,
            SizedBox(
              height: 80,
              child: Stepper(
                steps: [
                  Step(
                      title: const Text('Clean'),
                      content: const Text('Cleaning Files'),
                      isActive: step >= 0),
                  Step(
                      title: const Text('Config'),
                      content: const Text('Setting Config'),
                      isActive: step >= 1),
                  Step(
                      title: const Text('Building'),
                      content: const Text('Building Files'),
                      isActive: step >= 2),
                  Step(
                      title: const Text('Done'),
                      content: const Text('Apk Generated'),
                      isActive: step >= 3),
                ],
                connectorColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? ColorAssets.theme
                        : ColorAssets.grey),
                type: StepperType.horizontal,
                currentStep: step,
              ),
            ),
            30.hBox,
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                  child: SelectableText(
                    lines.join('\n'),
                    style: AppFontStyle.lato(14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            30.hBox,
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                OutlinedButtonWidget(
                  width: 120,
                  text: 'Cancel',
                  onTap: () {
                    shell.kill();
                    AnimatedDialog.hide(context);
                  },
                ),
                if (step == 3) ...[
                  30.wBox,
                  FilledButtonWidget(
                    text: 'Open Apk',
                    width: 120,
                    onTap: () {
                      shell.run(
                          'open ${widget.path}/build/app/outputs/flutter-apk');
                    },
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  void runScripts() async {
    for (final command in [
      'flutter create . --platforms=android',
      'sed  -i  -e \'s/<application/<uses-permission android:name="android.permission.INTERNET"\\/><application/g\' android/app/src/main/AndroidManifest.xml',
      'flutter build apk --release'
    ]) {
      final result = await shell.run(command);
      print('RESULT ${result.map((e) => '${e.outText} || ${e.errText}')}');
      setState(() {
        step++;
      });
    }
  }

  void _listen(List<int> event) {
    lines.add(utf8.decode(event));
    Future.delayed(const Duration(milliseconds: 600), () {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
    setState(() {});
  }
}
