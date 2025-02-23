import 'package:flutter/material.dart';

import '../../../common/extension_util.dart';
import '../../../common/firebase_image.dart';
import '../../../common/interactive_viewer/interactive_viewer_updated.dart';
import '../../../constant/font_style.dart';
import '../../../models/templates/template_model.dart';
import '../../../widgets/button/app_close_button.dart';
import '../../navigation/animated_dialog.dart';

class TemplateViewerWidget extends StatefulWidget {
  final FVBTemplate template;

  const TemplateViewerWidget({super.key, required this.template});

  @override
  State<TemplateViewerWidget> createState() => _TemplateViewerWidgetState();
}

class _TemplateViewerWidgetState extends State<TemplateViewerWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.template.name,
                style: AppFontStyle.headerStyle(),
              ),
              AppCloseButton(onTap: () => AnimatedDialog.hide(context)),
            ],
          ),
          30.hBox,
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            width: double.infinity,
            child: CustomInteractiveViewer(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    for (final image in widget.template.imageURLs)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 24,
                                spreadRadius: 8)
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: FirebaseImage(
                          image,
                          width: 200,
                          errorBuilder: (context, _, __) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                              20.hBox,
                              Text(
                                'Image not found',
                                style: AppFontStyle.lato(
                                  16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          fit: BoxFit.scaleDown,
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
