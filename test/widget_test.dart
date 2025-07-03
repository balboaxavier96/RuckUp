import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitpod_flutter_quickstart/main.dart'; // Contains RuckUpApp

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    // Load the app widget
    await tester.pumpWidget(const RuckUpApp());

    // Check if "Welcome to RuckUp" text exists (from login screen)
    expect(find.text('Welcome to RuckUp'), findsOneWidget);

    // You could test other elements like the login button
    expect(find.text('Log In'), findsOneWidget);
  });
}
