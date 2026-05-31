import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'features/news/data/news_repository.dart';
import 'features/news/news_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const useFirebase = bool.fromEnvironment('USE_FIREBASE');
  var firebaseEnabled = false;
  if (useFirebase) {
    try {
      await Firebase.initializeApp();
      firebaseEnabled = true;
    } catch (_) {
      firebaseEnabled = false;
    }
  }
  runApp(
    ProviderScope(
      overrides: [firebaseEnabledProvider.overrideWithValue(firebaseEnabled)],
      child: const DailyNewsApp(),
    ),
  );
}

class DailyNewsApp extends StatelessWidget {
  const DailyNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily News',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const NewsDashboardPage(),
    );
  }
}
