import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/weighing_controller.dart';
import '../services/ble_service.dart';

class WeighingLandscapeScreen extends StatelessWidget {
  const WeighingLandscapeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeighingController>();
    final ble = context.watch<BleService>();
    final currentWeightFormatted = ble.currentWeight.toStringAsFixed(2);
    final metrics = controller.metrics;

    // Cálculo da faixa zootécnica
    final double limInf = metrics.pesoMedio > 0 ? metrics.limiteInferior : 2.13;
    final double limSup = metrics.pesoMedio > 0 ? metrics.limiteSuperior : 2.61;

    return Scaffold(
      backgroundColor: const Color(0xFF030712), // Fundo escuro conforme imagem
      body: SafeArea(
        child: Stack(
          children: [
            // Efeito visual sutil de grid/pontos
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: GridPaper(
                  color: Colors.orangeAccent,
                  divisions: 2,
                  subdivisions: 2,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // 1. TOP BAR: "JJ AGRO • ESP32 HX711 ONLINE" + BADGE "● PESO ESTÁVEL"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão Voltar + Nome do Dispositivo
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                            tooltip: 'Trocar Galpão / Gaiola',
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEA580C),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEA580C).withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'JJ AGRO  •  ESP32  HX711  ONLINE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),

                      // Status de Estabilidade do Peso
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: controller.isWeightStable
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: controller.isWeightStable
                                ? const Color(0xFF10B981).withOpacity(0.6)
                                : Colors.amber.withOpacity(0.6),
                            width: 1.2,
                          ),
                          boxShadow: controller.isWeightStable
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              controller.isWeightStable ? Icons.check_circle_outline : Icons.sync,
                              color: controller.isWeightStable ? const Color(0xFF10B981) : Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              controller.isWeightStable ? '● PESO ESTÁVEL' : '○ OSCILANDO...',
                              style: TextStyle(
                                color: controller.isWeightStable ? const Color(0xFF10B981) : Colors.amber,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 2. CENTRO: NÚMERO GIGANTE EM LARANJA + DIAGNÓSTICO ZOOTÉCNICO + PACOTE BLE
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Peso Gigante Laranja: "2.45 kg"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currentWeightFormatted,
                            style: const TextStyle(
                              color: Color(0xFFEA580C),
                              fontSize: 100,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -4,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'kg',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Pill de Faixa Ideal: "✓ Peso Ideal do Lote (2.13 a 2.61 kg)"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          '✓ Peso Ideal do Lote (${limInf.toStringAsFixed(2)} a ${limSup.toStringAsFixed(2)} kg)',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // String de Telemetria BLE: "Pacote BLE Recebido: GALPAO:01;GAIOLA:01;PESO:2.45..."
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            children: [
                              const TextSpan(
                                text: 'Pacote BLE Recebido: ',
                                style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: ble.latestRawData.isNotEmpty
                                    ? ble.latestRawData
                                    : 'GALPAO:${controller.selectedGalpao};GAIOLA:${controller.selectedGaiola};PESO:$currentWeightFormatted;DATA:25/08/2026;HORA:07:42',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 3. RODAPÉ: BOTÃO REGISTRAR PESAGEM (LARANJA) + BOTÃO ZERAR/TARA DO GANCHO (ESCURO)
                  Row(
                    children: [
                      // Botão "+ REGISTRAR PESAGEM (MANUAL)"
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: const Color(0xFFEA580C).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 22, color: Colors.white),
                            label: const Text(
                              '+ REGISTRAR PESAGEM (MANUAL)',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                            ),
                            onPressed: ble.currentWeight > 0.05
                                ? () => controller.recordCurrentWeight(isAuto: false)
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Botão "ZERAR / TARA DO GANCHO"
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B1120),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.sync, size: 20, color: Color(0xFFEA580C)),
                            label: const Text(
                              'ZERAR / TARA DO GANCHO',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                            ),
                            onPressed: () async {
                              await ble.sendTareCommand();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Comando de Tara executado: Balança zerada.'),
                                    backgroundColor: Color(0xFFEA580C),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
