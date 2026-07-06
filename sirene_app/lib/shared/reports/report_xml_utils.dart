String xmlEscape(String? value) {
  final v = value ?? '';
  return v
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String xmlAttr(String name, Object? value) {
  if (value == null) return '';
  final text = '$value'.trim();
  if (text.isEmpty) return '';
  return ' $name="${xmlEscape(text)}"';
}

String xmlElement(String tag, {Map<String, Object?> attrs = const {}, String? text}) {
  final attrStr = attrs.entries
      .where((e) => e.value != null && '$e.value'.trim().isNotEmpty)
      .map((e) => xmlAttr(e.key, e.value))
      .join();
  if (text == null || text.isEmpty) {
    return '<$tag$attrStr/>';
  }
  return '<$tag$attrStr>${xmlEscape(text)}</$tag>';
}

String xmlDocument(String rootTag, String body, {String? generatedAt}) {
  final stamp = generatedAt ?? DateTime.now().toIso8601String();
  return '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<$rootTag${xmlAttr('geradoEm', stamp)}>\n'
      '$body\n'
      '</$rootTag>\n';
}
