/// Lenient readers for response bodies.
///
/// The API contract gives field names but no schema, so a model reads what
/// it can: a number sent as a string, an id sent as a number, a list that is
/// missing. What a model cannot do without — an id — it checks itself and
/// throws, which the data source reports as an unexpected failure.
library;

/// A string, or a number rendered as one. Null for anything else and for
/// blank text.
String? asString(Object? value) {
  final text = switch (value) {
    String() => value,
    num() => value.toString(),
    _ => null,
  };
  return text == null || text.trim().isEmpty ? null : text;
}

int? asInt(Object? value) => switch (value) {
      int() => value,
      num() => value.round(),
      String() => int.tryParse(value.trim()) ??
          double.tryParse(value.trim())?.round(),
      _ => null,
    };

double? asDouble(Object? value) => switch (value) {
      num() => value.toDouble(),
      String() => double.tryParse(value.trim()),
      _ => null,
    };

/// `true`/`false`, `1`/`0`, `"true"`/`"1"`.
bool? asBool(Object? value) => switch (value) {
      bool() => value,
      num() => value != 0,
      String() => switch (value.trim().toLowerCase()) {
          'true' || '1' => true,
          'false' || '0' => false,
          _ => null,
        },
      _ => null,
    };

/// An ISO 8601 time in local time, or null.
DateTime? asDate(Object? value) {
  final text = asString(value);
  return text == null ? null : DateTime.tryParse(text)?.toLocal();
}

/// A JSON object, or an empty one.
Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

/// The objects in a JSON array, skipping anything that is not one.
List<Map<String, dynamic>> asMapList(Object? value) => [
      if (value is List)
        for (final entry in value)
          if (entry is Map) Map<String, dynamic>.from(entry),
    ];

/// The strings in a JSON array.
List<String> asStringList(Object? value) => [
      if (value is List)
        for (final entry in value) ?asString(entry),
    ];

/// [asString], or a [FormatException] naming [field] — for what a model
/// cannot exist without.
String requireString(Object? value, String field) =>
    asString(value) ?? (throw FormatException('Missing "$field"'));
