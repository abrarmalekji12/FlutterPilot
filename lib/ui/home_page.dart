import 'package:flutter/material.dart';
import 'package:flutter_builder/data_type.dart';
import 'package:flutter_builder/screen_model.dart';
import 'package:flutter_builder/ui/component_selection.dart';

import '../component_list.dart';
import '../component_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScreenConfig screenConfig = screenConfigs[0];
  Component root = componentList['Container']!();

  _HomePageState() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: Row(
          children: [
            Expanded(
              child: _buildLeftSide(),
            ),
            SizedBox(
              width: 150,
              child: ComponentSelection(),
            ),
            SizedBox(
              width: 200,
              child: _buildPropertySelection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSide() {
    return Container(
      color: const Color(0xfff2f2f2),
      child: Center(
        child: Container(
          width: screenConfig.width,
          height: screenConfig.height,
          child: root.create(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
        ),
      ),
    );
  }


  Widget _buildPropertySelection() {
    return Column(
      children: [for (final param in root.parameters) _buildParameter(param)],
    );
  }

  Widget _buildParameter(Parameter? param) {
    if (param == null) return Container();
    switch (param.runtimeType) {
      case SimpleParameter:
        return _buildSimpleParameter(param as SimpleParameter);
      case ChoiceParameter:
        return _buildChoiceParameter(param as ChoiceParameter);
      case ComplexParameter:
        return _buildComplexParameter(param as ComplexParameter);
      default:
        return Container();
    }
  }

  Widget _buildSimpleParameter(SimpleParameter parameter) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Text(
            parameter.name,
            style: const TextStyle(fontSize: 13, color: Colors.black,fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: parameter.val),
              onChanged: (value) {
                if (parameter.paramType == ParamType.string) {
                  parameter.val = value;
                } else if (parameter.paramType == ParamType.double) {
                  parameter.val = double.parse(value);
                } else if (parameter.paramType == ParamType.int) {
                  parameter.val = int.parse(value);
                }
                setState(() {});
              },
              decoration: const InputDecoration(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChoiceParameter(ChoiceParameter param) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(param.name,style: const TextStyle(fontSize: 14,color: Colors.black,fontWeight: FontWeight.bold),),
        Column(
          children: [
            for (final subParam in param.options)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Radio<Parameter>(
                            value: param.rawValue,
                            groupValue: subParam,
                            onChanged: (value) {
                              param.val = subParam;
                              setState(() {});
                            }),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(subParam.name,style: const TextStyle(fontSize: 14,color: Colors.black),),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(child: _buildParameter(subParam)),
                ],
              )
          ],
        ),
      ],
    );
  }

  Widget _buildComplexParameter(ComplexParameter param) {
    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(param.name,style: const TextStyle(fontSize: 14,color: Colors.black,fontWeight: FontWeight.bold),),
        Column(
          children: [
            for (final subParam in param.params)
              _buildParameter(subParam)
          ],
        ),
      ],
    );
  }
}
