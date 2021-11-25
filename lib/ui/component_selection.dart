import 'package:flutter/material.dart';
import 'package:flutter_builder/component_list.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:provider/provider.dart';

class ComponentSelection extends StatefulWidget {
  const ComponentSelection({Key? key}) : super(key: key);

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
                  Provider.of<ComponentSelectionCubit>(context,listen: false).changeComponentSelection(componentList[e]!());
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
