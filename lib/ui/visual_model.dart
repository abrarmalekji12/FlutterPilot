import 'dart:ui';

import 'package:equatable/equatable.dart';

class Boundary extends Equatable{
  final Rect rect;
  final String name;
  const Boundary(this.rect, this.name);

  @override
  List<Object?> get props => [rect,name];
  @override
  bool operator ==(Object other) {
    return other is Boundary && rect == other.rect && name != other.name;
  }
}

class NormalBoundary extends Boundary {
  NormalBoundary(Rect rect, String name) : super(rect, name);
}

class HighlightedBoundary extends Boundary {
  HighlightedBoundary(Rect rect, String name) : super(rect, name);
}
