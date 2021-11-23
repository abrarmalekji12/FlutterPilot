import 'package:flutter/material.dart';
import 'package:flutter_builder/component_list.dart';

class ComponentSelection extends StatefulWidget {
  const ComponentSelection({Key? key}) : super(key: key);

  @override
  _ComponentSelectionState createState() => _ComponentSelectionState();
}

class _ComponentSelectionState extends State<ComponentSelection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: componentList
          .map(
            (e) => InkWell(
              child: Text(e.name),
            ),
          )
          .toList(),
    );
  }
}
