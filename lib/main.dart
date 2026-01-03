import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iwak_peyek/pages/splash_screen.dart';
import 'package:iwak_peyek/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      theme: ThemeData(primarySwatch: Colors.green),
      routes: {'/main': (context) => MainPage()},
    );
  }
}
