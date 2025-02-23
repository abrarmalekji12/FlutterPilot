import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';

import '../../bloc/suggestion_code/suggestion_code_bloc.dart';
import '../../constant/color_assets.dart';
import '../../constant/font_style.dart';
import '../../injector.dart';
import '../../models/function_model.dart';

const double kSuggestionBoxPadding = 5,
    kSuggestionBoxHeight = 250,
    kSuggestionTileHeight = 25;

class SuggestionWidget extends StatelessWidget {
  final SuggestionCodeBloc suggestionCodeBloc;

  const SuggestionWidget({Key? key, required this.suggestionCodeBloc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: ColorAssets.colorD0D5EF,
            width: 0.6,
          ),
          color: theme.background1,
        ),
        height: !isDesktop ? kSuggestionBoxHeight : null,
        child: BlocConsumer<SuggestionCodeBloc, SuggestionCodeState>(
          bloc: suggestionCodeBloc,
          buildWhen: (previous, current) =>
              current is SuggestionSelectionChangeState,
          listener: (context, state) {
            if (state is SuggestionSelectionChangeState) {
              final position = -kSuggestionBoxHeight +
                  (state.selectionIndex + 2) * kSuggestionTileHeight;
              if (position > 0) {
                controller.animateTo(
                  position,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          },
          builder: (context, state) {
            return ListView.builder(
              controller: controller,
              itemBuilder: (context, index) {
                return SuggestionTileWidget(
                  onSelected: () {
                    suggestionCodeBloc.add(SuggestionSelectedEvent(index));
                  },
                  suggestionTile:
                      suggestionCodeBloc.suggestion!.suggestions[index],
                  text: suggestionCodeBloc.suggestion!.code,
                  selected: suggestionCodeBloc.selectionIndex == index,
                );
              },
              itemCount: suggestionCodeBloc.suggestion?.suggestions.length ?? 0,
              shrinkWrap: true,
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
    final (String, Color)? indicator = switch (suggestionTile.type) {
      SuggestionType.variable => ('v', Colors.blue.shade300),
      SuggestionType.function => ('f', Colors.purple.shade600),
      SuggestionType.staticFun => ('f', Colors.green.shade300),
      SuggestionType.staticVar => ('f', Colors.green.shade600),
      SuggestionType.builtInFun => ('o', Colors.amber),
      SuggestionType.builtInVar => ('o', Colors.amber),
      SuggestionType.classes => ('c', Colors.blue.shade600),
      SuggestionType.fvbEnum => ('e', Colors.cyan.shade600),
      _ => null
    };
    return InkWell(
      onTap: () {
        onSelected.call();
      },
      child: Container(
        height: kSuggestionTileHeight,
        decoration: BoxDecoration(
          color: selected ? ColorAssets.theme.withOpacity(0.2) : getColor,
        ),
        padding: const EdgeInsets.all(kSuggestionBoxPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (indicator != null)
              Container(
                width: 14,
                height: 14,
                decoration:
                    BoxDecoration(color: indicator.$2, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  indicator.$1,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(
              width: 4,
            ),
            SuggestionText(
              text: suggestionTile.title,
              word: text,
              style: AppFontStyle.lato(13,
                  color: theme.text1Color.withOpacity(0.9),
                  fontWeight: FontWeight.normal),
            ),
            const SizedBox(
              width: 3,
            ),
            if (value is FVBVariable)
              Expanded(
                child: Text(
                  DataType.dataTypeToCode(value.dataType),
                  style: AppFontStyle.lato(12,
                      color: ColorAssets.theme, fontWeight: FontWeight.w900),
                ),
              )
            else if (value is FVBFunction)
              Expanded(
                child: Text(
                  value.suggestionPreviewCode,
                  style: AppFontStyle.lato(12,
                      color: theme.text1Color.withOpacity(0.7),
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (suggestionTile.type == SuggestionType.builtInFun)
              Expanded(
                child: Text(
                  (value as FunctionModel).description,
                  style: AppFontStyle.lato(12,
                      color: theme.text1Color.withOpacity(0.7),
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (suggestionTile.type == SuggestionType.classes)
              Expanded(
                child: Text(
                  (value as FVBClass)
                          .getDefaultConstructor
                          ?.suggestionPreviewCode ??
                      '',
                  style: AppFontStyle.lato(12,
                      color: theme.text1Color.withOpacity(0.7),
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (!suggestionTile.global && !selected)
              Text(
                suggestionTile.scope,
                style: AppFontStyle.lato(11,
                    color: theme.text2Color, fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Color get getColor {
    if (suggestionTile.type == SuggestionType.staticVar ||
        suggestionTile.type == SuggestionType.staticFun) {
      return Colors.blue.shade100;
    }
    return suggestionTile.global ? theme.background3 : theme.background1;
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
            text: text.substring(index, index + word.length),
            style: style.copyWith(
                color: theme.text1Color, fontWeight: FontWeight.w900)),
        if (index + word.length < text.length)
          TextSpan(text: text.substring(index + word.length), style: style),
      ]),
    );
  }
}
