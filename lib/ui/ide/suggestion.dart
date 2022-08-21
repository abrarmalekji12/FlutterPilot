import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/key_fire/key_fire_bloc.dart';
import '../../bloc/suggestion_code/suggestion_code_bloc.dart';
import '../../common/compiler/code_processor.dart';
import '../../common/custom_popup_menu_button.dart';
import '../../common/responsive/responsive_widget.dart';
import '../../constant/app_colors.dart';
import '../../constant/font_style.dart';
import '../../models/function_model.dart';

class SuggestionWidget extends StatelessWidget {
  final SuggestionCodeBloc suggestionCodeBloc;

  const SuggestionWidget({Key? key, required this.suggestionCodeBloc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: !Responsive.isLargeScreen(context) ? dw(context, 100) : 350,
        height: Responsive.isLargeScreen(context) ? null : 150,
        child: BlocBuilder<SuggestionCodeBloc, SuggestionCodeState>(
          bloc: suggestionCodeBloc,
          buildWhen: (previous, current) =>
              current is SuggestionSelectionChangeState,
          builder: (context, state) {
            return ListView.builder(
              itemBuilder: (context, index) {
                return SuggestionTileWidget(
                  onSelected: () {
                    suggestionCodeBloc.selectionIndex = index;
                    context.read<KeyFireBloc>().add(FireKeyDownWithTypeEvent(FireKeyType.enter));
                  },
                  suggestionTile:
                      suggestionCodeBloc.suggestion!.suggestions[index],
                  text: suggestionCodeBloc.suggestion!.code,
                  selected: suggestionCodeBloc.selectionIndex == index,
                );
              },
              itemCount: suggestionCodeBloc.suggestion?.suggestions.length ?? 0,
              shrinkWrap: Responsive.isLargeScreen(context),
            );
          },
        ),
      ),
    );
  }
}

class SuggestionTileWidget extends StatelessWidget {
  final SuggestionTile suggestionTile;
  final String text;
  final bool selected;
  final VoidCallback onSelected;

  const SuggestionTileWidget(
      {Key? key,
      required this.suggestionTile,
      required this.text,
      required this.onSelected,
      required this.selected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = suggestionTile.value;
    return InkWell(
      onTap: () {
        onSelected();
      },
      child: Container(
        decoration: BoxDecoration(
            color: getColor,
            border: selected
                ? const Border(
                    bottom: BorderSide(color: AppColors.theme, width: 1.5))
                : null),
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            SuggestionText(
              text: suggestionTile.title,
              word: text,
              style: AppFontStyle.roboto(14,
                  color: Colors.white, fontWeight: FontWeight.normal),
            ),
            const SizedBox(
              width: 10,
            ),
            if (value is FVBVariable)
              Expanded(
                child: Text(
                  DataType.dataTypeToCode(value.dataType),
                  style: AppFontStyle.roboto(12,
                      color: AppColors.theme, fontWeight: FontWeight.w600),
                ),
              )
            else if (value is FVBFunction)
              Expanded(
                child: Text(
                  value.samplePreviewCode,
                  style: AppFontStyle.roboto(12,
                      color: AppColors.theme, fontWeight: FontWeight.w600),
                ),
              )
            else if (suggestionTile.type == SuggestionType.builtInFun)
              Expanded(
                child: Text(
                  (value as FunctionModel).description,
                  style: AppFontStyle.roboto(12,
                      color: AppColors.theme, fontWeight: FontWeight.w600),
                ),
              )
            else if (suggestionTile.type == SuggestionType.classes)
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 5,
                    ),
                    const Icon(
                      Icons.data_object,
                      color: AppColors.theme,
                      size: 14,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                        (value as FVBClass)
                                .getDefaultConstructor
                                ?.samplePreviewCode ??
                            '',
                        style: AppFontStyle.roboto(12,
                            color: AppColors.theme,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            if (!suggestionTile.global)
              Text(suggestionTile.scope,
                  style: AppFontStyle.roboto(11,
                      color: Colors.grey, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Color get getColor {
    if (suggestionTile.type == SuggestionType.staticVar ||
        suggestionTile.type == SuggestionType.staticFun) {
      return Colors.pink.shade900;
    }
    return suggestionTile.global ? AppColors.darkGrey2 : AppColors.darkGrey;
  }
}

class SuggestionText extends StatelessWidget {
  final String text;
  final String word;
  final TextStyle style;

  const SuggestionText(
      {Key? key, required this.text, required this.word, required this.style})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final index = text.indexOf(word);
    if (index == -1) {
      return Text(text, style: style);
    }
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: text.substring(0, index), style: style),
        TextSpan(
            text: word, style: style.copyWith(color: AppColors.theme.shade100)),
        if (index + word.length < text.length)
          TextSpan(text: text.substring(index + word.length), style: style),
      ]),
    );
  }
}
