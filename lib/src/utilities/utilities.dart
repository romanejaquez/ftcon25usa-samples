/// Szudzik's function for hashing two ints together
int szudzik(int a, int b) {
  // a and b must be >= 0
  int x = a.abs();
  int y = b.abs();
  return x >= y ? x * x + x + y : x + y * y;
}

extension RiveIterableExtensions<T> on Iterable<T> {
  /// The element at position [index] of this iterable, or the [first] element.
  ///
  /// The [index] is zero based.
  ///
  /// Returns the result of `elementAt(index)` if the iterable has at least
  /// `index + 1` elements, and [first] otherwise.
  T elementAtOrFirst(int index) {
    if (index < 0 || index >= length) {
      return first;
    }
    return elementAt(index);
  }
}
