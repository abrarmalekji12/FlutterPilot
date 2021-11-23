import 'package:flutter/material.dart';
import 'package:flutter_builder/ui/component_selection.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget? root;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildLeftSide()),
        Expanded(child: _buildRightSide()),
      ],
    );
  }

  Widget _buildLeftSide() {
    return root ?? Container();
  }

  Widget _buildRightSide() {
    return ComponentSelection();
  }
}
