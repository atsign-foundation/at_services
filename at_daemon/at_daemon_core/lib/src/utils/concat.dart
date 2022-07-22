// Used to keep the functions in path_provider.dart clean
// Shortens the syntax of returning null when attempting to concatenate a String to null
extension Concat on String {
  String concat(String o) => this + o;
}
