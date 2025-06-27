import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:proyecto_moviles2/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(); // Carga variables de .env

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final apiKey = dotenv.env['HUGGINGFACE_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('ERROR: API Key no configurada');
  } else {
    print('API Key cargada correctamente');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Simple',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
