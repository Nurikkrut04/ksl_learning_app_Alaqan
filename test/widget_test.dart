import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ksl_learning_app/app.dart';
import 'package:ksl_learning_app/presentation/providers/auth_provider.dart';
import 'package:ksl_learning_app/presentation/providers/language_provider.dart';
import 'package:ksl_learning_app/presentation/providers/connectivity_provider.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MyApp), findsOneWidget);
  });
}
