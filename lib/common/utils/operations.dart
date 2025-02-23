bool listEqualsCheck<T>(List<T>? a, List<T>? b, bool Function(T, T) check) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (!check.call(a[index], b[index])) {
      return false;
    }
  }
  return true;
}
