import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant/app_colors.dart';
import '../constant/font_style.dart';

class InputBox extends StatelessWidget {
  final String title;
  final void Function(String)? onChanged;
  final TextEditingController controller;
  final TextInputType inputType;
  final double fontSize;
  final String? initial;
  final String? hint;
  final bool enable;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool vertical;

  const InputBox(
      {required this.title,
        Key? key,
        required this.controller,
        this.inputType = TextInputType.text,
        this.onChanged,
        this.initial,
        this.fontSize = 16,
        this.hint,
        this.enable = true,
        this.onTap,
        this.formatters,
        this.validator,
        this.readOnly = false,
        this.vertical = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
        validator: validator?? (String? value){
          if(controller.text.isEmpty){
            return 'Please enter $title';
          }
          return null;
        },
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: TextField(
                  onChanged: (String value) {
                    onChanged?.call(value);
                  },
                  onTap: onTap,
                  controller: controller,
                  keyboardType: inputType,
                  style: AppFontStyle.roboto(14),
                  readOnly: !enable,
                  textAlignVertical: TextAlignVertical.center,
                  inputFormatters: formatters,
                  decoration: InputDecoration(
                    alignLabelWithHint: false,
                    contentPadding: EdgeInsets.zero,
                    prefix: const SizedBox(
                      width: 18,
                    ),
                    suffix: const SizedBox(
                      width: 18,
                    ),
                    hintText: hint ?? title,
                    helperStyle: AppFontStyle.roboto(14),
                    hintStyle:
                    AppFontStyle.roboto(14, color: AppColors.color72788AGrey),
                    errorStyle: AppFontStyle.roboto(13, color: AppColors.red),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.borderColor,
                        width: 1,
                      ),
                      gapPadding: 0,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.borderColor,
                        width: 1,
                      ),
                      gapPadding: 0,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.borderColor,
                        width: 1,
                      ),
                      gapPadding: 0,
                    ),
                    enabled: enable,
                  ),
                  obscureText: false,
                  textInputAction: TextInputAction.next,
                ),
              ),
              if (field.hasError)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * -10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            field.errorText ?? '',
                            style: AppFontStyle.roboto(12,
                                color: AppColors.colorED3737
                                    .withOpacity(value)),
                          )
                        ],
                      ),
                    );
                  },
                  duration: const Duration(milliseconds: 300),
                )
            ],
          );
        }
    );
  }
}
