import 'package:flutter_test/flutter_test.dart';
import 'package:toolor_app/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ToolorApp());
    expect(find.text('TOOLOR'), findsAny);
  });
}
