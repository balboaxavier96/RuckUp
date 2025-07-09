import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// App UI
import 'screens/matches_screen.dart';
import 'screens/liked_you_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyB0z_tT1sY9M2oyXWJVDSQpLvfqvoPhwTw',
      authDomain: 'ruckup-c4cf1.firebaseapp.com',
      projectId: 'ruckup-c4cf1',
      storageBucket: 'ruckup-c4cf1.appspot.com',
      messagingSenderId: '1034961980508',
      appId: '1:1034961980508:web:cdb2f3bc13b7ad43602a99',
    ),
  );

  if (!kIsWeb) {
    final messaging = FirebaseMessaging.instance;

    // Ask for permissions on mobile
    await messaging.requestPermission();

    final token = await messaging.getToken();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  // ✅ Run the app
  runApp(const RuckUpApp());
}

/// 🧑‍💻 Main User App
class RuckUpApp extends StatefulWidget {
  const RuckUpApp({super.key});

  @override
  State<RuckUpApp> createState() => _RuckUpAppState();
}

class _RuckUpAppState extends State<RuckUpApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuckUp',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: WelcomeScreen(onToggleTheme: _toggleTheme),
      routes: {
        '/matches': (_) => const MatchesScreen(),
        '/liked-you': (_) => const LikedYouScreen(),
      },
    );
  }
}
