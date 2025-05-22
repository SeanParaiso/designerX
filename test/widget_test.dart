// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fe_art/main.dart';

void main() {
  testWidgets('App should render login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ArtDesignApp());

    // Verify that the login screen is shown
    expect(find.text('The Artchive'), findsOneWidget);
    expect(find.text('Your Digital Art Gallery'), findsOneWidget);
  });
}
