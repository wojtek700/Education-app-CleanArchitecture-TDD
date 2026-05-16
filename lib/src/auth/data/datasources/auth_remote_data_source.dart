import 'package:education_app/core/enums/update_user.dart';
import 'package:education_app/src/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  const AuthRemoteDataSource();
  Future<void> forgotPassword(String email);

  Future<LocalUserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String fullName,
    required String password,
  });

  Future<void> updateUser({
    required UpdateUserAction action,
    dynamic userData,
  });
}
