import 'dart:convert';

import 'package:flutter/material.dart';

import '../../common/app_button.dart';
import '../../common/common_methods.dart';
import '../../common/extension_util.dart';
import '../../constant/font_style.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../widgets/button/app_close_button.dart';
import '../home/landing_page.dart';
import '../navigation/animated_dialog.dart';

class FirestoreAssistantTool extends StatefulWidget {
  const FirestoreAssistantTool({Key? key}) : super(key: key);

  @override
  State<FirestoreAssistantTool> createState() => _FirestoreAssistantToolState();
}

class _FirestoreAssistantToolState extends State<FirestoreAssistantTool> {
  final TextEditingController initializeController = TextEditingController();
  final TextEditingController pathController = TextEditingController();
  final TextEditingController docIdController = TextEditingController();
  final TextEditingController dataController = TextEditingController();
  bool connected = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Firebase Cloud-Firestore Assistant',
                style: AppFontStyle.headerStyle(),
              ),
              AppCloseButton(
                onTap:()=> AnimatedDialog.hide(context),

              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          CommonTextField(
            border: true,
            maxLines: 5,
            hintText: 'Initialize',
            controller: initializeController,
          ),
          const SizedBox(
            height: 20,
          ),
          AppButton(
            height: 40,
            title: 'Connect',
            onPressed: () {
              dataBridge
                  .connect('Test', jsonDecode(initializeController.text))
                  .then((value) {
                connected = true;
                setState(() {});
              });
            },
          ),
          if (connected) ...[
            const SizedBox(
              height: 20,
            ),
            Column(
              children: [
                CommonTextField(
                  border: true,
                  maxLines: 1,
                  hintText: 'collection/path',
                  controller: pathController,
                ),
                const SizedBox(
                  height: 10,
                ),
                CommonTextField(
                  border: true,
                  maxLines: 1,
                  hintText: 'doc id (optional)',
                  controller: docIdController,
                ),
                const SizedBox(
                  height: 10,
                ),
                CommonTextField(
                  border: true,
                  maxLines: 5,
                  hintText: 'json',
                  controller: dataController,
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        height: 40,
                        title: 'ADD',
                        onPressed: () {
                          final map = jsonDecode(dataController.text);
                          final path = pathController.text;
                          if (path.split('/').length % 2 == 0) {
                            showAlertDialog(
                                context, 'Alert', 'Invalid path to collection');
                            return;
                          }
                          dataBridge
                              .assistOperationAdd(
                                  path,
                                  docIdController.text.isNotEmpty
                                      ? docIdController.text
                                      : null,
                                  map)
                              .then((value) {
                            showAlertDialog(
                                context, 'Alert', 'Added Successfully');
                          });
                        },
                      ),
                    ),
                    20.wBox,
                    Expanded(
                      child: AppButton(
                        height: 40,
                        title: 'Update',
                        onPressed: () {
                          final map = jsonDecode(dataController.text);
                          final path = pathController.text;
                          if (path.split('/').length % 2 == 0) {
                            showAlertDialog(
                                context, 'Alert', 'Invalid path to collection');
                            return;
                          }
                          dataBridge
                              .assistOperationUpdate(
                                  path,
                                  docIdController.text.isNotEmpty
                                      ? docIdController.text
                                      : null,
                                  map)
                              .then((value) {
                            showAlertDialog(
                                context, 'Alert', 'Added Successfully');
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
