typedef JsonMap = Map<String, dynamic>;

class ApiPayloadParser {
  ApiPayloadParser._();

  static String extractMessage(
    dynamic data, {
    required String fallback,
  }) {
    final map = data is JsonMap ? data : null;
    final message = map?['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return fallback;
  }

  static JsonMap requireObject(
    dynamic data, {
    String errorMessage = 'Unexpected response format',
  }) {
    final wrapped = _wrappedObjectOrNull(data);
    if (wrapped != null) {
      return wrapped;
    }

    if (data is JsonMap && !data.containsKey('data')) {
      return data;
    }

    throw Exception(errorMessage);
  }

  static List<dynamic> listData(dynamic data) {
    final wrapped = _wrappedListOrNull(data);
    if (wrapped != null) {
      return wrapped;
    }

    if (data is List) {
      return List<dynamic>.from(data);
    }

    return const <dynamic>[];
  }

  static List<T> parseList<T>(
    dynamic data, {
    required T Function(JsonMap json) fromJson,
  }) {
    final items = listData(data);
    return items
        .map((item) => fromJson(_castJsonMap(item)))
        .toList(growable: false);
  }

  static List<T> parseListValues<T>(
    dynamic data, {
    required T Function(dynamic value) fromValue,
  }) {
    final items = listData(data);
    return items.map(fromValue).toList(growable: false);
  }

  static JsonMap? paginatedDataMapOrNull(dynamic data) {
    final wrapped = _wrappedObjectOrNull(data);
    if (wrapped != null && wrapped['content'] is List) {
      return wrapped;
    }

    if (data is JsonMap && data['content'] is List) {
      return data;
    }

    return null;
  }

  static T parseValue<T>(
    dynamic data, {
    required T Function(dynamic payload) parser,
  }) {
    if (data is JsonMap && data.containsKey('data')) {
      return parser(data['data']);
    }

    return parser(data);
  }

  static JsonMap _castJsonMap(dynamic value) {
    if (value is JsonMap) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw Exception('Unexpected response format');
  }

  static JsonMap? _wrappedObjectOrNull(dynamic data) {
    if (data is JsonMap && data['data'] is JsonMap) {
      return data['data'] as JsonMap;
    }

    return null;
  }

  static List<dynamic>? _wrappedListOrNull(dynamic data) {
    if (data is JsonMap && data['data'] is List) {
      return List<dynamic>.from(data['data'] as List);
    }

    return null;
  }
}
