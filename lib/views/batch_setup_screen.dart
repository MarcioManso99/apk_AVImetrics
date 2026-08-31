import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/weighing_controller.dart';
import '../services/ble_service.dart';
import 'weighing_landscape_screen.dart';
import 'ble_scan_screen.dart';
import 'metrics_screen.dart';
import 'history_screen.dart';

class BatchSetupScreen extends StatelessWidget {
  const BatchSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeighingController>();
    final ble = context.watch<BleService>();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // Header JJ Agro
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.scale, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'JJ AGRO',
                            style: TextStyle(
                              color: Color(0xFFEA580C),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Produtos Agropecuários & Assistência Técnica',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Ações de Topo (Bluetooth & Histórico)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ble.isConnected ? const Color(0xFF10B981) : Colors.orangeAccent,
                          side: BorderSide(
                            color: ble.isConnected ? const Color(0xFF10B981).withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(ble.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching, size: 16),
                        label: Text(ble.isConnected ? 'ESP32 Conectado' : 'Conectar Balança', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BleScanScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Ver Métricas',
                        icon: const Icon(Icons.analytics_outlined, color: Colors.white70),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MetricsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Histórico & Excel',
                        icon: const Icon(Icons.history, color: Colors.white70),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Card Central de Seleção de Galpão e Gaiola
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Lado Esquerdo: Seleção do Galpão
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '1. SELECIONE O GALPÃO',
                              style: TextStyle(
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 2.2,
                                ),
                                itemCount: 9,
                                itemBuilder: (context, index) {
                                  final numStr = (index + 1).toString().padLeft(2, '0');
                                  final isSelected = controller.selectedGalpao == numStr;
                                  return InkWell(
                                    onTap: () => controller.setGalpao(numStr),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFF97316) : Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        'Galpão $numStr',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const VerticalDivider(color: Colors.white12, width: 32),

                      // Lado Direito: Seleção da Gaiola e Botão Iniciar Pesagem
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '2. SELECIONE A GAIOLA / LOTE',
                              style: TextStyle(
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.8,
                                ),
                                itemCount: 12,
                                itemBuilder: (context, index) {
                                  final numStr = (index + 1).toString().padLeft(2, '0');
                                  final isSelected = controller.selectedGaiola == numStr;
                                  return InkWell(
                                    onTap: () => controller.setGaiola(numStr),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFF97316) : Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        'Gaiola $numStr',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Botão Gigante de Iniciar Pesagem
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEA580C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 6,
                                  shadowColor: const Color(0xFFEA580C).withOpacity(0.5),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                                label: Text(
                                  'INICIAR PESAGEM: GALPÃO ${controller.selectedGalpao} • GAIOLA ${controller.selectedGaiola}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const WeighingLandscapeScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
