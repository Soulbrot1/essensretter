class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {}

class InputException implements Exception {
  final String message;
  InputException(this.message);
}

class ParsingException implements Exception {
  final String message;
  ParsingException(this.message);
}
