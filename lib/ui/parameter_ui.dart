import 'package:flutter/material.dart';
import 'package:flutter_builder/common/custom_animated_dialog.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_property/component_property_cubit.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../data_type.dart';

class ChoiceParameterWidget extends StatelessWidget {
  final ChoiceParameter parameter;
  const ChoiceParameterWidget({Key? key,required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parameter.name,
          style: const TextStyle(
              fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: StatefulBuilder(builder: (context, setStateForChoiceChange) {
            return Column(
              children: [
                for (final subParam in parameter.options)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<Parameter>(
                          value: parameter.rawValue,
                          groupValue: subParam,
                          onChanged: (value) {
                            parameter.val = subParam;
                            setStateForChoiceChange(() {});
                            Provider.of<ComponentPropertyCubit>(context,listen: false).changedProperty();
                          }),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(subParam.name,style: AppFontStyle.roboto(14,fontWeight: FontWeight.w600),),
                      if(parameter.rawValue==subParam)
                      Expanded(
                        child: ParameterWidget(parameter: subParam,),
                      ),
                    ],
                  )
              ],
            );
          }),
        ),
      ],
    );
  }
}
class ParameterWidget extends StatelessWidget {
  final Parameter? parameter;
  const ParameterWidget({Key? key, this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (parameter == null) return Container();
    if (parameter.runtimeType.toString().startsWith('SimpleParameter')) {
      // print('paramm ${param.name} ${param.runtimeType}');
      return SimpleParameterWidget(parameter:parameter as SimpleParameter);
    }
    switch (parameter.runtimeType) {
      case ChoiceParameter:
        return ChoiceParameterWidget(parameter: parameter as ChoiceParameter,);
      case ComplexParameter:
        return ComplexParameterWidget(parameter: parameter as ComplexParameter,);
      case ChoiceValueParameter:
        return ChoiceValueParameterWidget(parameter:parameter as ChoiceValueParameter);
      default:
        return Container();
    }
  }
}
class SimpleParameterWidget extends StatelessWidget {
  final SimpleParameter parameter;
  const SimpleParameterWidget({Key? key,required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Text(
            parameter.name,
            style: AppFontStyle.roboto(13,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 10,
          ),
          
          SizedBox(
            width: 50,
            child: TextField(
              // key:  parameter.name=='color'?GlobalObjectKey('simple ${parameter.name}'):null,
              onTap: (){
                CustomAnimatedDialog.show(context, ColorPicker(pickerColor: Colors.blueAccent, onColorChanged: (color){
                  parameter.val=color;
                }), GlobalObjectKey('simple ${parameter.name}'));
              },
              controller: TextEditingController.fromValue(
                  TextEditingValue(text: '${parameter.rawValue}')),
              onChanged: (value) {
                if (parameter.paramType == ParamType.string) {
                  parameter.val = value;
                } else if (parameter.paramType == ParamType.double) {
                  parameter.val = double.tryParse(value);
                } else if (parameter.paramType == ParamType.int) {
                  parameter.val = int.tryParse(value);
                }
                Provider.of<ComponentPropertyCubit>(context,listen: false).changedProperty();
              },
              decoration: const InputDecoration(),
            ),
          )
        ],
      ),
    );
  }
}

class ChoiceValueParameterWidget extends StatelessWidget {
  final ChoiceValueParameter parameter;
  const ChoiceValueParameterWidget({Key? key,required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   parameter.name,
        //   style: const TextStyle(
        //       fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
        // ),
        StatefulBuilder(builder: (context, setStateForSelectionChange) {
          return SizedBox(
            height: 45,
            child: CustomDropdownButton<String>(
              value: parameter.rawValue,
              hint: Text(
                'select ${parameter.name}',
                style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              ),
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              selectedItemBuilder: (_, key) {
                return Text(
                  key,
                  style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                );
              },
              items: parameter.options.keys
                  .map(
                    (e) => CustomDropdownMenuItem<String>(
                  value: e,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      e,
                      style: AppFontStyle.roboto(14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              )
                  .toList(),
              onChanged: (key) {
                parameter.val = key;
                setStateForSelectionChange(() {});
                Provider.of<ComponentPropertyCubit>(context,listen: false).changedProperty();
              },
            ),
          );
        })
      ],
    );
  }
}
class ComplexParameterWidget extends StatelessWidget {
  final ComplexParameter parameter;
  const ComplexParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   parameter.name,
        //   style: const TextStyle(
        //       fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
        // ),
        Expanded(
          child: Column(
            children: [
              for (final subParam in parameter.params) ParameterWidget(parameter: subParam,)
            ],
          ),
        ),
      ],
    );
  }
}




