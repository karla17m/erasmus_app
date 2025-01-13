import 'package:flutter_test/flutter_test.dart';
import 'package:app_final/main.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    // Construiește aplicația și declanșează primul cadru.
    await tester.pumpWidget( MyApp());

    // Verifică dacă există câmpurile de email și parolă.
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verifică dacă există butonul de login.
    expect(find.text('Login'), findsWidgets); // Modifică findsOneWidget -> findsWidgets pentru mai multe apariții.
  });
}
