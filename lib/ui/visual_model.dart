import 'dart:ui';

import 'package:equatable/equatable.dart';

import '../models/fvb_ui_core/component/component_model.dart';

class Boundary extends Equatable {
  final Rect rect;
  final Component comp;
  final VoidCallback? onTap;
  final String? errorMessage;
  const Boundary(this.rect, this.comp, {this.onTap, this.errorMessage});

  @override
  List<Object?> get props => [rect, comp];
  @override
  bool operator ==(Object other) {
    return other is Boundary && rect == other.rect && comp != other.comp;
  }
}

class NormalBoundary extends Boundary {
  const NormalBoundary(Rect rect, String name, Component component)
      : super(rect, component);
}

class HighlightedBoundary extends Boundary {
  const HighlightedBoundary(Rect rect, String name, Component component)
      : super(rect, component);
}
