import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/weighing_controller.dart';
import 'services/ble_service.dart';
import 'services/database_service.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Travar orientação preferencial para fácil manuseio no galpão
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      child: const BalancaAvicolaApp(),
    ),
  );
}

class BalancaAvicolaApp extends StatelessWidget {
  const BalancaAvicolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balança Avícola Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Verde Agro Industrial
          primary: const Color(0xFF1B5E20),
          secondary: const Color(0xFFFF8F00), // Laranja Destaque
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
