class PathException implements Exception {
  final String message;
  PathException(this.message);
}

class IsolateException implements Exception {
  final String message;
  IsolateException(this.message);
}

class OnboardException implements Exception {
  final String message;
  OnboardException(this.message);
}
