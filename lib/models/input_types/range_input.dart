abstract class SimpleInputOption {}

class RangeInput<T> extends SimpleInputOption {
  final T start;
  final T end;
  final T step;
  RangeInput(this.start, this.end, this.step);
}
