import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/theme/app_theme.dart';

void main() {
  test('light theme keeps primary app surfaces white', () {
    final theme = AppTheme.lightTheme;

    expect(theme.colorScheme.surface, Colors.white);
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.appBarTheme.backgroundColor, Colors.white);
    expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
    expect(theme.navigationBarTheme.backgroundColor, Colors.white);
    expect(theme.navigationBarTheme.surfaceTintColor, Colors.transparent);
  });
}
