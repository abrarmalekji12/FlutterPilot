import 'package:equatable/equatable.dart';

import '../components/component_impl.dart';
import '../ui/boundary_widget.dart';
import 'fvb_ui_core/component/component_model.dart';
import 'fvb_ui_core/component/custom_component.dart';

final kNullWidget = CNotRecognizedWidget();

class ComponentSelectionModel extends Equatable {
  final List<Component> treeSelection;
  final List<Component> visualSelection;
  final Component propertySelection;
  final Component intendedSelection;
  final Component root;
  final Viewable? viewable;
  factory ComponentSelectionModel.empty() {
    return ComponentSelectionModel.unique(kNullWidget, kNullWidget);
  }
  factory ComponentSelectionModel.unique(
      final Component component, Component root,
      {Viewable? screen}) {
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
        treeSelection, visualSelection, propertySelection, component, root,
        viewable: screen);
  }

  ComponentSelectionModel(this.treeSelection, this.visualSelection,
      this.propertySelection, this.intendedSelection, this.root,
      {this.viewable});

  @override
  List<Object?> get props => [
        treeSelection,
        visualSelection,
        propertySelection,
        intendedSelection,
        root
      ];
}
