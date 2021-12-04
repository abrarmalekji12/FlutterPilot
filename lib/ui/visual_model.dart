import 'dart:ui';

class Boundary  {
  final Rect rect;
  final String name;
  Boundary(this.rect, this.name);
  @override
  bool operator ==(Object other) {
    return other is Boundary&&rect==other.rect&&name!=other.name;
  }
}
class NormalBoundary extends Boundary{
  NormalBoundary(Rect rect, String name) : super(rect, name);
}

class HighlightedBoundary extends Boundary{
  HighlightedBoundary(Rect rect, String name) : super(rect, name);

}