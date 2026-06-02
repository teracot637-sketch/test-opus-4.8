import 'package:flutter_test/flutter_test.dart';

import 'package:test_opus_4_8/main.dart';

void main() {
  testWidgets('показывает приветственный текст', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Привет лох'), findsOneWidget);
  });
}
