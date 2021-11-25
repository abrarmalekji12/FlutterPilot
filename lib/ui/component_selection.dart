import 'package:flutter/material.dart';
import 'package:flutter_builder/component_list.dart';
import 'package:flutter_builder/component_model.dart';

class ComponentSelection extends StatefulWidget {
  final void Function(Component) onSelected;
  const ComponentSelection({Key? key, required this.onSelected}) : super(key: key);

  @override
  _ComponentSelectionState createState() => _ComponentSelectionState();
}

class _ComponentSelectionState extends State<ComponentSelection> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: componentList.keys
            .map(
              (e) => InkWell(
                onTap: (){
                  widget.onSelected(componentList[e]!());
                },
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Center(child: Text(e,style: const TextStyle(color: Colors.black,fontSize: 14),)),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey,width: 2),
                    borderRadius: BorderRadius.circular(10)
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
