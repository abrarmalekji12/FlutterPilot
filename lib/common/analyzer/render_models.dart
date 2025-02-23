import 'package:flutter/material.dart';

import '../../components/component_list.dart';
import '../../models/fvb_ui_core/component/component_model.dart';

mixin CRenderModel {
  Size get size;
  Size get childSize;
  EdgeInsets get margin;
  EdgeInsets get padding => EdgeInsets.zero;
  bool get settle => false;
}
mixin CParentFlexModel {
  int get flex;
}

mixin CLeafRenderModel {
  Future<Size> size(Size size);
  Size? get fixedSize;
}

mixin CBoxScrollModel {
  Axis get direction;
  List<Component> get children;
}

mixin ComplexRenderModel {
  Size get size;
  ComponentSize childSize(String child);
}
mixin CFlexModel {
  Axis get direction;
  MainAxisSize get mainAxisSize;
  CrossAxisAlignment get crossAxisAlignment;
}
