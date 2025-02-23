import 'package:flutter/cupertino.dart';

import '../boundary_widget.dart';

class ViewableSelector extends ChangeNotifier {
  final List<Viewable> list = [];

  void update() {
    notifyListeners();
  }
}
