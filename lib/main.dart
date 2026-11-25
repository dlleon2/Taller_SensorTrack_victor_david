import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

// =====================================================================
//  CONFIGURACIÓN DE SUPABASE
//  Reemplaza estos valores con los de tu proyecto en supabase.com
// =====================================================================
const String supabaseUrl = 'TU_SUPABASE_URL';
const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
// =====================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (supabaseUrl != 'TU_SUPABASE_URL' &&
        supabaseAnonKey != 'TU_SUPABASE_ANON_KEY') {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    }
  } catch (e) {
    debugPrint('Supabase no inicializado todavía: $e');
  }

  runApp(const SensorTrackApp());
}

class SensorTrackApp extends StatelessWidget {
  const SensorTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SensorTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
