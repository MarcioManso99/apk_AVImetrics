import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/weighing_controller.dart';
import 'services/ble_service.dart';
import 'services/database_service.dart';
import 'views/batch_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Travar orientação obrigatória em Modo Paisagem / Tela Deitada (Landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Esconder barra de status do sistema para visualização imersiva máxima no galpão
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Inicializar banco de dados SQLite local
  await DatabaseService.instance.initDatabase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BleService>(
          create: (_) => BleService(),
        ),
        ChangeNotifierProxyProvider<BleService, WeighingController>(
          create: (context) => WeighingController(
            bleService: Provider.of<BleService>(context, listen: false),
            dbService: DatabaseService.instance,
          ),
          update: (context, bleService, previous) =>
              previous ?? WeighingController(
                bleService: bleService,
                dbService: DatabaseService.instance,
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
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF030712), // Fundo escuro premium JJ Agro
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEA580C), // Laranja Primário JJ Agro
          primary: const Color(0xFFEA580C),
          secondary: const Color(0xFFF97316),
          surface: const Color(0xFF0F172A),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF030712),
          foregroundColor: Colors.white,
        ),
      ),
      home: const BatchSetupScreen(),
    );
  }
}
