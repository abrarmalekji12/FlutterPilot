import 'component_model.dart';

class ComponentSelectionModel {
  final List<Component> treeSelection;
  final List<Component> visualSelection;
  final Component propertySelection;
  factory ComponentSelectionModel.unique(final Component component) {
    return ComponentSelectionModel([component], [component], component);
  }
  ComponentSelectionModel(
      this.treeSelection, this.visualSelection, this.propertySelection);
}
