import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, catch error if already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully!");
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print("ℹ️ Firebase was already initialized - continuing normally");
    } else {
      print("❌ Firebase initialization error: ${e.message}");
      rethrow;
    }
  }

  // Initialize Firebase Remote Config
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? const Duration(minutes: 5)
          : const Duration(hours: 1),
    ));

    await remoteConfig.setDefaults({
      'openai_api_key': '',
    });

    await remoteConfig.fetchAndActivate();

    final apiKey = remoteConfig.getString('openai_api_key');

    if (kDebugMode) {
      if (apiKey.isNotEmpty) {
        print('✅ OpenAI API Key loaded from Remote Config');
        print('   Key prefix: ${apiKey.substring(0, 7)}...');
      } else {
        print('❌ WARNING: OPENAI_API_KEY not found in Remote Config');
      }
    }
  } catch (e) {
    print('❌ Error initializing Remote Config: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CitySync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}