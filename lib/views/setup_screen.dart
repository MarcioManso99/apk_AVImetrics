import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../controllers/weighing_controller.dart';
import 'weighing_screen.dart';
import 'history_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _selectedGalpao = 1;
  int _selectedGaiola = 1;

  Future<void> _dispararEnvioNuvem(BuildContext context) async {
    final sync = SyncService(dbService: DatabaseService.instance);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Enviando dados para a Central..."),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF0F172A),
      ),
    );

    final ok = await sync.sendDirectToCentral(
      endpointUrl: "https://ais-dev-kvlyq6zsd6wwhkv6nqacj4-373503873765.us-west1.run.app/api/v1/pesagens",
      apiKey: "avimetrics_secret_key_2026",
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? "✓ Pesagens gravadas e consolidadas na Central AVImetrics!"
                : "Sem resposta da Central. Verifique a internet ou exporte em CSV.",
          ),
          backgroundColor: ok ? const Color(0xFF10B981) : Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _abrirModalBluetooth(BuildContext context) {
    final ble = context.read<BleService>();
    ble.loadPairedDevices();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Consumer<BleService>(
        builder: (context, bleService, child) {
          final devices = bleService.scanResults;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bluetooth_searching_rounded, color: Color(0xFFEA580C), size: 24),
                          SizedBox(width: 10),
                          Text(
                            "BALANÇAS PAREADAS",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                        onPressed: () => bleService.loadPairedDevices(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Selecione o ESP32 pareado no seu celular:",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (devices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "Nenhuma balança encontrada.\nPareie 'AVImetrics_Scale' nas configurações do Android.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final isThisConnected = bleService.connectedDevice?.address == device.address && bleService.isConnected;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isThisConnected ? const Color(0xFF10B981) : const Color(0xFFEA580C)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.bluetooth_connected_rounded,
                                color: isThisConnected ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                              ),
                            ),
                            title: Text(
                              device.name ?? "Dispositivo Desconhecido",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              device.address,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: isThisConnected
                                ? const Text(
                                    "CONECTADO",
                                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEA580C),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await bleService.connectToDevice(device);
                                    },
                                    child: const Text("CONECTAR", style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final controller = context.read<WeighingController>();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            children: [
              // COLUNA DA ESQUERDA: SELEÇÃO
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
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        InkWell(
                          onTap: () => _abrirModalBluetooth(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ble.isConnected ? const Color(0xFF10B981) : Colors.redAccent.withOpacity(0.5),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
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
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.bluetooth,
                                  size: 16,
                                  color: ble.isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                                ),
                              ],
                            ),
                          ),
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
                                  color: isSelected ? const Color(0xFFEA580C) : Colors.white12,
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
                                  color: isSelected ? const Color(0xFFEA580C) : Colors.white12,
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

              // COLUNA DA DIREITA: AÇÕES RÁPIDAS
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          const Text("LOTE CONFIGURADO", style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF030712),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEA580C)),
                                ),
                                child: Text("GALPÃO ${_selectedGalpao.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF030712),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEA580C)),
                                ),
                                child: Text("GAIOLA ${_selectedGaiola.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          // BOTAO 1: ENVIAR PARA NUVEM (ROXO)
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _dispararEnvioNuvem(context),
                              icon: const Icon(Icons.cloud_upload_rounded, size: 15, color: Colors.white),
                              label: const Text(
                                "ENVIAR PARA A NUVEM",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // BOTAO 2: EXPORTAR CSV / WHATSAPP (VERDE)
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final sync = SyncService(dbService: DatabaseService.instance);
                                await sync.exportAndShareCsv(context);
                              },
                              icon: const Icon(Icons.table_chart_rounded, size: 15, color: Colors.white),
                              label: const Text(
                                "EXPORTAR CSV (WHATSAPP)",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // BOTAO 3: HISTÓRICO / APAGAR (AZUL)
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF030712),
                                side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                                );
                              },
                              icon: const Icon(Icons.list_alt_rounded, size: 15, color: Color(0xFF38BDF8)),
                              label: const Text(
                                "HISTÓRICO / APAGAR",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF38BDF8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // BOTAO 4: TARA (CINZA/LARANJA)
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF030712),
                                side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                ble.sendTareCommand();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Comando de Tara enviado!"),
                                    duration: Duration(milliseconds: 700),
                                    backgroundColor: Color(0xFFEA580C),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.sync_rounded, size: 15, color: Color(0xFFEA580C)),
                              label: const Text(
                                "ZERAR / TARA GANCHO",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // BOTAO 5: INICIAR PESAGEM (LARANJA DESTAQUE)
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 3,
                              ),
                              onPressed: () {
                                controller.setGalpao("Galpão ${_selectedGalpao.toString().padLeft(2, '0')}");
                                controller.setGaiola("Lote ${_selectedGaiola.toString().padLeft(2, '0')}");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const WeighingScreen()),
                                );
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text(
                                "INICIAR PESAGEM",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
                              ),
                            ),
                          ),
                        ],
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
