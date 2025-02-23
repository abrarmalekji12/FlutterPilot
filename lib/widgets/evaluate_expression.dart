import 'package:flutter/material.dart';
import 'package:fvb_processor/compiler/code_processor.dart';

import '../code_operations.dart';
import '../common/custom_extension_tile.dart';
import '../common/extension_util.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../injector.dart';
import '../ui/fvb_code_editor.dart';
import '../ui/parameter_ui.dart';

class EvaluateExpression extends StatefulWidget {
  final Processor processor;

  const EvaluateExpression({Key? key, required this.processor})
      : super(key: key);

  @override
  State<EvaluateExpression> createState() => _EvaluateExpressionState();
}

class _EvaluateExpressionState extends State<EvaluateExpression> {
  FVBCacheValue? output;
  String? error;
  String code = '';
  final Debounce _debounce = Debounce(const Duration(milliseconds: 400));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.border1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTileTheme(
        dense: true,
        child: CustomExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          collapsedBackgroundColor: theme.border1,
          title: Text(
            'Evaluate Expression',
            style: AppFontStyle.lato(14, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 6),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FVBCodeEditor(
                  code: code,
                  onCodeChange: (value, r) {
                    code = value;
                    _debounce.run(() {
                      try {
                        Processor.error = false;

                        disableError = true;
                        Processor.operationType = OperationType.regular;
                        output = widget.processor.process(
                            CodeOperations.trim(
                              code,
                            )!,
                            suggestion: false,
                            config: ProcessorConfig(
                                unmodifiable: true,
                                errorCallback: (value, _) {
                                  error = value;
                                  setState(() {});
                                }));
                        disableError = false;
                        error = Processor.error ? Processor.errorMessage : null;
                        widget.processor.errorSuppress = false;
                      } on Exception catch (e) {
                        print('ERROR ${e.toString()}');
                      }
                      setState(() {});
                    });
                  },
                  onErrorUpdate: (message, error) {},
                  config: FVBEditorConfig(
                    parentProcessorGiven: true,
                    multiline: false,
                    smallBottomBar: true,
                    shrink: true,
                  ),
                  processor: widget.processor,
                ),
                5.hBox,
                Container(
                  alignment: Alignment.topLeft,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: ColorAssets.borderColor,
                      ),
                      borderRadius: BorderRadius.circular(6)),
                  constraints: const BoxConstraints(maxHeight: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SelectableText(
                                  error ?? output?.value.toString() ?? '',
                                  style: AppFontStyle.lato(
                                      error != null ? 12 : 13,
                                      color: error != null
                                          ? ColorAssets.red
                                          : null),
                                ),
                              ),
                              if (error == null && output != null)
                                Text(
                                  output?.dataType.toString() ?? '',
                                  style: AppFontStyle.lato(
                                    13,
                                    fontWeight: FontWeight.normal,
                                  ).copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                10.hBox,
              ],
            )
          ],
        ),
      ),
    );
  }
}
