// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cv_builder/main.dart';

void main() {
  testWidgets('CV Builder home screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CVBuilderApp());

    // Verify that CV Builder title is displayed
    expect(find.text('CV Builder'), findsOneWidget);
    expect(find.text('Create your professional resume in minutes'),
        findsOneWidget);

    // Wait for dialog animation to complete
    await tester.pumpAndSettle();

    // Verify that the dialog appears with the correct title
    expect(find.text("Let's get started"), findsOneWidget);
    expect(find.text('How do you want to create your resume?'), findsOneWidget);

    // Verify that all resume creation options are displayed
    expect(find.text('Create new resume'), findsOneWidget);
    expect(find.text('Create with AI assistance'), findsOneWidget);
    expect(find.text('Upload resume'), findsOneWidget);
    expect(find.text('Create with LinkedIn profile'), findsOneWidget);
    expect(find.text('Create from example'), findsOneWidget);
  });
}
