import 'package:education_app/core/common/app/providers/user_provider.dart';
import 'package:education_app/src/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get size => mediaQuery.size;
  double get height => size.height;
  double get width => size.width;

  UserProvider get userProvider => read<UserProvider>();

  LocalUser? get currentUser => userProvider.user;
}
