/// Check if a list of items is equal to another list of items. Lists are
/// considered equal if they have the same number of values and each of those
/// values are equal. A custom [equalityCheck] can be provided for objects that
/// don't override their equality operator or need to be deemed equal based on
/// varying application logic.
bool listEquals<T>(List<T> list1, List<T> list2,
    {bool Function(T a, T b)? equalityCheck}) {
  if (identical(list1, list2)) return true;
  int length = list1.length;
  if (length != list2.length) return false;
  // A little more verbose to wrap the loop with the conditional but more
  // efficient at runtime.
  if (equalityCheck != null) {
    for (int i = 0; i < length; i++) {
      if (!equalityCheck(list1[i], list2[i])) {
        return false;
      }
    }
  } else {
    for (int i = 0; i < length; i++) {
      if (list1[i] != list2[i]) {
        return false;
      }
    }
  }
  return true;
}

/// Check if an iterable is equal to another iterable. Iterables are considered
/// equal if they have the same number of values and each of those values are
/// equal. A custom [equalityCheck] can be provided for objects that don't
/// override their equality operator or need to be deemed equal based on varying
/// application logic.
bool iterableEquals<T>(Iterable<T>? list1, Iterable<T>? list2,
    {bool Function(T a, T b)? equalityCheck}) {
  if (list1 == null || list2 == null) {
    return false;
  }
  if (identical(list1, list2)) return true;
  int length = list1.length;
  if (length != list2.length) return false;

  var a = list1.iterator;
  var b = list2.iterator;
  // A little more verbose to wrap the loop with the conditional but more
  // efficient at runtime.
  if (equalityCheck != null) {
    // Iterator starts at null current value, must be moved to first value.
    while (a.moveNext() && b.moveNext()) {
      if (!equalityCheck(a.current, b.current)) {
        return false;
      }
    }
  } else {
    // Iterator starts at null current value, must be moved to first value.
    while (a.moveNext() && b.moveNext()) {
      if (a.current != b.current) {
        return false;
      }
    }
  }

  return true;
}

/// Checks that all the retrieved values for an item are the same. If they're
/// the same, it returns the equal value, otherwise it'll return null.  A custom
/// [equalityCheck] can be provided for objects that don't override their
/// equality operator or need more sophisticated rules of equality (for example
/// if your [K] is a collection). TODO: have two functions; one to check is all
/// are equal, another to get the value?
K? equalValue<T, K>(Iterable<T> items, K? Function(T a) getValue,
    {bool Function(K? a, K? b)? equalityCheck}) {
  if (items.isEmpty) {
    return null;
  }

  var iterator = items.iterator;
  // Move to first value.
  iterator.moveNext();
  K? value = getValue(iterator.current);

  // A little more verbose to wrap the loop with the conditional but more
  // efficient at runtime.
  if (equalityCheck != null) {
    while (iterator.moveNext()) {
      if (!equalityCheck(value, getValue(iterator.current))) {
        return null;
      }
    }
  } else {
    while (iterator.moveNext()) {
      if (value != getValue(iterator.current)) {
        return null;
      }
    }
  }
  return value;
}

/// Returns true if all the elemnts in iterable1 are contained in iterable2.
/// Assumes there are no dupes in either iterable.
bool setEquals<T>(Iterable<T>? it1, Iterable<T>? it2) {
  if (it1 == null || it2 == null) {
    return false;
  }
  if (it1.length != it2.length) {
    return false;
  }
  for (final a in it1) {
    if (!it2.contains(a)) {
      return false;
    }
  }
  return true;
}
