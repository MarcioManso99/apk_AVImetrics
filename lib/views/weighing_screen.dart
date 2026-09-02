import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../controllers/weighing_controller.dart';

class WeighingScreen extends StatefulWidget {
  const WeighingScreen({super.key});

  @override
  State<WeighingScreen> createState() => _WeighingScreenState();
}

class _WeighingScreenState extends State<WeighingScreen> {
  bool _autoRecord = true;

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final controller = context.watch<WeighingController>();

    final weight = ble.currentWeight;
    final isStable = ble.isStable;
    final isConnected = ble.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070D18),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              "AVImetrics",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                "${controller.currentGalpao} • ${controller.currentGaiola}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFFF97316)),
            tooltip: "Zerar / Tara",
            onPressed: () {
              ble.sendTareCommand();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Comando de Tara enviado!"),
                  duration: Duration(milliseconds: 600),
                  backgroundColor: Color(0xFFEA580C),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              // MOSTRADOR DO PESO OCUPANDO A TELA
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1526),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected
                          ? (isStable ? const Color(0xFF10B981) : const Color(0xFF38BDF8).withOpacity(0.5))
                          : Colors.white10,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Badge de status no canto superior esquerdo
                      Positioned(
                        top: 14,
                        left: 16,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected ? const Color(0xFF10B981) : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected ? "CONECTADO" : "DESCONECTADO",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge Estável / Oscilando no canto superior direito
                      Positioned(
                        top: 14,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isStable ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isStable ? "• ESTÁVEL" : "○ OSCILANDO",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isStable ? const Color(0xFF10B981) : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                      // Valor numérico central
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weight.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF38BDF8),
                                letterSpacing: -2,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "QUILOGRAMAS (KG)",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // SWITCH GRAVAÇÃO AUTOMÁTICA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gravação Automática ao Estabilizar",
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Registra quando o peso estabilizar por > 1s",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: _autoRecord,
                        activeColor: const Color(0xFFEA580C),
                        onChanged: (val) => setState(() => _autoRecord = val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // BOTÃO REGISTRAR PESAGEM LOGO ABAIXO DO PESO
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                  ),
                  onPressed: () {
                    controller.recordCurrentWeight();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pesagem Registrada!"),
                        duration: Duration(milliseconds: 600),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 22),
                  label: const Text(
                    "REGISTRAR PESAGEM MANUAL",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
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
