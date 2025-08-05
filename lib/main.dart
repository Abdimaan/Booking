import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tqprwfogyjpnhzpqslug.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxcHJ3Zm9neWpwbmh6cHFzbHVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NjY2ODYsImV4cCI6MjA2OTM0MjY4Nn0.jPmmFn5MJghEv_VCxwDOw-VnRqsQoRXrIQ2JKykI66U',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}
