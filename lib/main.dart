import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/ble_service.dart';
import 'services/database_service.dart';
import 'controllers/weighing_controller.dart';
import 'views/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Trava em modo Paisagem (Landscape) e ativa tela cheia imersiva
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final dbService = DatabaseService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BleService>(
          create: (_) => BleService(),
        ),
        ChangeNotifierProxyProvider<BleService, WeighingController>(
          create: (context) => WeighingController(
            bleService: Provider.of<BleService>(context, listen: false),
            dbService: dbService,
          ),
          update: (context, ble, controller) =>
              controller ??
              WeighingController(
                bleService: ble,
                dbService: dbService,
              ),
        ),
      ],
      child: const JJAgroApp(),
    ),
  );
}

class JJAgroApp extends StatelessWidget {
  const JJAgroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JJ Agro - Balança Avícola Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFFEA580C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEA580C),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF0F172A),
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SetupScreen(),
    );
  }
}
