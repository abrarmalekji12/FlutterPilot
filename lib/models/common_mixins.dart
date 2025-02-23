import 'package:collection/collection.dart';

import 'fvb_ui_core/component/component_model.dart';
import 'fvb_ui_core/component/custom_component.dart';
import 'other_model.dart';

mixin ImageExtractor {
  void extractImages(Component component, List<FVBImage> images) {
    component.forEachWithClones((p0) {
      if (p0.hasImageAsset) {
        final imageData = p0.parameters[0].value;
        if (imageData != null &&
            images.firstWhereOrNull((element) =>
                    (imageData as FVBImage).name == element.name) ==
                null) {
          images.add(imageData as FVBImage);
        }
      }
      return false;
    });
  }
}

mixin CustomComponentExtractor {
  void extractCustomComponents(
      Component component, List<CustomComponent> list) {
    component.forEachWithClones((p0) {
      if (p0 is CustomComponent) {
        if (list.firstWhereOrNull((element) => element.name == p0.name) ==
            null) {
          list.add(p0);
        }
      }
      return false;
    });
  }
}
