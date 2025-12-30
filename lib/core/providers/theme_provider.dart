import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../theme/app_theme.dart';

part 'theme_provider.g.dart';

@riverpod
ThemeData appTheme(Ref ref) {
  return AppTheme.lightTheme;
}
