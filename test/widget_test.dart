import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pms/views/auth/login_screen.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    expect(find.text('PMS Admin'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
  });
}
