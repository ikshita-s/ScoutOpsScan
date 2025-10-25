
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'homepage.dart';
import 'services/database.dart';

void main() async {
  // Initialize Flutter bindings first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Set the app to fullscreen immersive mode (after binding is initialized)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize database with adapter registration
  await initializeDatabase();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Hide the status bar
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      home: Homepage(),
    );
  }
}

Future<void> initializeDatabase() async {
  // Create a temporary DataManager instance to initialize the database
  final dbManager = DataManager();
  await dbManager.init();
}
