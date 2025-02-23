import '../../view_model/auth_viewmodel.dart';

class AuthResponse {
  final String? error;
  final FVBUser? user;

  AuthResponse(this.error, this.user);

  factory AuthResponse.left(FVBUser user) {
    return AuthResponse(null, user);
  }
  factory AuthResponse.right(String error) {
    return AuthResponse(error, null);
  }
}
