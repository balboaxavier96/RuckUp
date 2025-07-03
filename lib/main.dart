import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyB0z_tT1sY9M2oyXWJVDSQpLvfqvoPhwTw',
      authDomain: 'ruckup-c4cf1.firebaseapp.com',
      projectId: 'ruckup-c4cf1',
      storageBucket: 'ruckup-c4cf1.appspot.com', // ✅ fixed from .app to .app**spot.com**
      messagingSenderId: '1034961980508',
      appId: '1:1034961980508:web:cdb2f3bc13b7ad43602a99',
    ),
  );
  runApp(const RuckUpApp());
}

class RuckUpApp extends StatelessWidget {
  const RuckUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuckUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}
