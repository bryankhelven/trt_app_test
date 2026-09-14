import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarot_app/app/app.dart';

void main() {
  testWidgets('Given first launch, when opened, then home is accessible', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TarotApp()));
    await tester.pumpAndSettle();
    expect(find.text('ARCANUM'), findsOneWidget);
    expect(find.text('Tiragem Livre'), findsOneWidget);
    expect(find.text('Cruz Celta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
