import 'component_model.dart';

class ComponentSelectionModel {
  final List<Component> treeSelection;
  final List<Component> visualSelection;
  final Component propertySelection;
  final Component intendedSelection;
  final Component root;
  factory ComponentSelectionModel.unique(
      final Component component, Component root) {
    final List<Component> visualSelection = [];
    final List<Component> treeSelection = [];
    final Component propertySelection;

    ///... root.objects.map((e) => CustomComponent.findSameLevelComponent(e, root, component)),
    if (root is CustomComponent) {
      treeSelection.addAll([
        component,
      ]);
      visualSelection.addAll(component.cloneElements);
      propertySelection = component;
    } else {
      treeSelection.add(component);
      visualSelection.add(component);
      propertySelection = component;
    }
    return ComponentSelectionModel(
        treeSelection, visualSelection, propertySelection, component, root);
  }

  ComponentSelectionModel(this.treeSelection, this.visualSelection,
      this.propertySelection, this.intendedSelection, this.root);
}
