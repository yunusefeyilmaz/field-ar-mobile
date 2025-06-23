import 'package:field_ar/data/services/user_service.dart';
import 'package:field_ar/features/field/fields_screen.dart';
import 'package:field_ar/features/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [const Locale('en', 'US'), const Locale('tr', 'TR')],
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    final userService = UserService();
    final storage = userService.storage;

    return FutureBuilder<String?>(
      future: storage.readToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data != null) {
          return FieldsScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
