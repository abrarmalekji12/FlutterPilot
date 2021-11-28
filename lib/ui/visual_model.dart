import 'dart:ui';

class Boundary{
  final Rect rect;
  final String name;
  Boundary(this.rect, this.name);
}
class NormalBoundary extends Boundary{
  NormalBoundary(Rect rect, String name) : super(rect, name);
}

class HighlightedBoundary extends Boundary{
  HighlightedBoundary(Rect rect, String name) : super(rect, name);

}