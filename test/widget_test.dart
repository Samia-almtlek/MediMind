// Basic widget test for MediMind app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medimind/main.dart';

void main() {
  testWidgets('MediMind app launches successfully', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MediMindApp());

    // Verify that the home screen loads with "Today" title
    expect(find.text('Today'), findsOneWidget);

    // Verify bottom navigation bar exists
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify the FAB (Floating Action Button) exists
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
