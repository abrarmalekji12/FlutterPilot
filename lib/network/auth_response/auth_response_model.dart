class AuthResponse {
  final String? error;
  final int? userId;

  AuthResponse(this.error, this.userId);

  factory AuthResponse.left(int userId) {
    return AuthResponse(null, userId);
  }
  factory AuthResponse.right(String error) {
    return AuthResponse(error, null);
  }
}
