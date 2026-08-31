import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/ble_service.dart';
import 'controllers/weighing_controller.dart';
import 'views/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Trava orientação em Paisagem e ativa modo imersivo
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BleService>(
          create: (_) => BleService()..init(),
        ),
        ChangeNotifierProxyProvider<BleService, WeighingController>(
          create: (context) => WeighingController(
            bleService: Provider.of<BleService>(context, listen: false),
          ),
          update: (context, ble, controller) =>
              controller ?? WeighingController(bleService: ble),
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
        scaffoldBackgroundColor: const Color(0xFF030712), // Fundo escuro profundo
        primaryColor: const Color(0xFFEA580C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEA580C), // Laranja JJ Agro
          secondary: Color(0xFF10B981), // Verde Esmeralda Estável
          surface: Color(0xFF0F172A), // Superfície Grafite
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SetupScreen(),
    );
  }
}
