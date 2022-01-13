import 'package:flutter/material.dart';
import '../component_list.dart';
import '../constant/font_style.dart';

class ComponentSelection extends StatefulWidget {
  const ComponentSelection({Key? key}) : super(key: key);

  @override
  _ComponentSelectionState createState() => _ComponentSelectionState();
}

class _ComponentSelectionState extends State<ComponentSelection> {
  final gridController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final componentKeys = componentList.keys.toList();
    return Padding(
      padding: const EdgeInsets.all(5),
      child: GridView.builder(
        scrollDirection: Axis.vertical,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
        controller: gridController,
        itemBuilder: (context, i) {
          return InkWell(
            onTap: () {
              // Provider.of<ComponentSelectionCubit>(context, listen: false)
              //     .changeComponentSelection(componentList[componentKeys[i]]!());
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Text(
                  componentKeys[i],
                  textAlign: TextAlign.center,
                  style: AppFontStyle.roboto(12, fontWeight: FontWeight.w500),
                ),
              ),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        itemCount: componentKeys.length,
      ),
    );
  }
}
