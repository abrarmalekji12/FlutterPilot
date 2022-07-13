import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/suggestion_code/suggestion_code_bloc.dart';
import '../../common/compiler/code_processor.dart';
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
      child: BlocBuilder(
          bloc: suggestionCodeBloc,
          builder: (context, state) {
            if (suggestionCodeBloc.suggestion == null) {
              return Container();
            }
            return Container(
              color: const Color(0xff494949),
              width: 350,
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return SuggestionTileWidget(
                    suggestionTile:
                        suggestionCodeBloc.suggestion!.suggestions[index],
                    text: suggestionCodeBloc.suggestion!.code,
                    selected: suggestionCodeBloc.selectionIndex == index,
                  );
                },
                itemCount: suggestionCodeBloc.suggestion!.suggestions.length,
                shrinkWrap: true,
              ),
            );
          }),
    );
  }
}

class SuggestionTileWidget extends StatelessWidget {
  final SuggestionTile suggestionTile;
  final String text;
  final bool selected;

  const SuggestionTileWidget(
      {Key? key,
      required this.suggestionTile,
      required this.text,
      required this.selected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = suggestionTile.value;
    return Container(
      decoration: BoxDecoration(
          color:
              getColor,
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
                  const SizedBox(width: 5,),
                  const Icon(Icons.data_object,color: AppColors.theme,size: 14,),
                  const SizedBox(width: 5,),
                  Expanded(
                    child: Text(
                      (value as FVBClass).getDefaultConstructor?.samplePreviewCode ?? '',
                      style: AppFontStyle.roboto(12,
                          color: AppColors.theme, fontWeight: FontWeight.w600),
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
    );
  }
Color get getColor {
   if(suggestionTile.type == SuggestionType.staticVar||suggestionTile.type==SuggestionType.staticFun){
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
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: text.substring(0, index), style: style),
        TextSpan(
            text: word, style: style.copyWith(color: AppColors.theme.shade100)),
        TextSpan(text: text.substring(index + word.length), style: style),
      ]),
    );
  }
}
