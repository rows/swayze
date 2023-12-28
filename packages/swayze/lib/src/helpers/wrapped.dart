/// Wrapper to allow the use of nullable properties
/// on copyWith style methods.
class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}
