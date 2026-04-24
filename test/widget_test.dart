// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:bs_bingo_caller/main.dart';

void main() {
  testWidgets('App shows loading state', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ebsBingoApp());

    // Initial frame should render the loading shell while cards are loading.
    expect(find.text('Loading 1,000 cards...'), findsOneWidget);
  });
}
