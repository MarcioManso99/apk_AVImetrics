import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../controllers/weighing_controller.dart';
import 'weighing_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _selectedGalpao = 1;
  int _selectedGaiola = 1;

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final controller = context.read<WeighingController>();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            children: [
              // Coluna da Esquerda: Seleção Galpão e Gaiola
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "SETUP DO LOTE DE PESAGEM",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Color(0xFFF97316),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ble.isConnected ? const Color(0xFF10B981) : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ble.isConnected ? "ESP32 CONECTADO" : "ESP32 DESCONECTADO",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ble.isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("SELECIONE O GALPÃO", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Expanded(
                      flex: 4,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 9,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, i) {
                          final galpaoNum = i + 1;
                          final isSelected = _selectedGalpao == galpaoNum;
                          return InkWell(
                            onTap: () => setState(() => _selectedGalpao = galpaoNum),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFF97316) : Colors.white12,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                "G${galpaoNum.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text("SELECIONE A GAIOLA / LOTE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Expanded(
                      flex: 5,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, i) {
                          final gaiolaNum = i + 1;
                          final isSelected = _selectedGaiola == gaiolaNum;
                          return InkWell(
                            onTap: () => setState(() => _selectedGaiola = gaiolaNum),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFF97316) : Colors.white12,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                "LOTE ${gaiolaNum.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.white70,
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
              const SizedBox(width: 20),
              // Coluna da Direita: Card de Ação
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text("LOTE CONFIGURADO", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF030712),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEA580C)),
                                ),
                                child: Text("GALPÃO ${_selectedGalpao.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF030712),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEA580C)),
                                ),
                                child: Text("GAIOLA ${_selectedGaiola.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          onPressed: () {
                            controller.setGalpao("Galpão ${_selectedGalpao.toString().padLeft(2, '0')}");
                            controller.setGaiola("Lote ${_selectedGaiola.toString().padLeft(2, '0')}");
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WeighingScreen()),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 28),
                              SizedBox(width: 8),
                              Text(
                                "INICIAR PESAGEM",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                              ),
                            ],
                          ),
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
