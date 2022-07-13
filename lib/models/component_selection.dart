import 'component_model.dart';

class ComponentSelectionModel {
  final List<Component> treeSelection;
  final List<Component> visualSelection;
  final Component propertySelection;
  final Component intendedSelection;
  factory ComponentSelectionModel.unique(final Component component) {
    return ComponentSelectionModel([component], [component], component,component);
  }
  ComponentSelectionModel(
      this.treeSelection, this.visualSelection, this.propertySelection, this.intendedSelection);
}
