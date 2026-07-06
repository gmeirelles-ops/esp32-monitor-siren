/// Valor seguro para [DropdownButtonFormField] quando a lista pode mudar de PC/rede.
T? validDropdownValue<T>(T? value, Iterable<T> items) {
  if (value == null) return null;
  for (final item in items) {
    if (item == value) return value;
  }
  return null;
}
