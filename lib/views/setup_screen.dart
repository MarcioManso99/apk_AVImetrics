import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
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

  void _abrirModalBluetooth(BuildContext context) {
    final ble = context.read<BleService>();
    ble.loadPairedDevices();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Consumer<BleService>(
        builder: (context, bleService, child) {
          final devices = bleService.scanResults;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

  void _abrirModalSincronizacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_sync_rounded, color: Color(0xFFEA580C), size: 26),
                  SizedBox(width: 10),
                  Text(
                    "SINCRONIZAR / EXPORTAR DADOS",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981)),
                ),
                title: const Text("Exportar CSV (WhatsApp / Baixar)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Gera arquivo formatado para importar na Central Web", style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final sync = SyncService(dbService: DatabaseService.instance);
                  await sync.exportAndShareCsv(context);
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send_rounded, color: Color(0xFFEA580C)),
                ),
                title: const Text("Enviar Direto para a Central (Nuvem)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Transfere as pesagens via internet se houver sinal", style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final sync = SyncService(dbService: DatabaseService.instance);
                  final ok = await sync.sendDirectToCentral(
                    endpointUrl: "https://api.jjagro.com.br/v1/pesagens",
                    apiKey: "SUA_API_KEY_AQUI",
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? "Lote sincronizado com sucesso!" : "Sem resposta da Central. Tente exportar em CSV."),
                        backgroundColor: ok ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            children: [
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
                          const Text("LOTE CONFIGURADO", style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF030712),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEA580C)),
                                ),
                                child: Text("GALPÃO ${_selectedGalpao.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF030712),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEA580C)),
                                ),
                                child: Text("GAIOLA ${_selectedGaiola.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF030712),
                                side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sync_rounded, color: Color(0xFFEA580C), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "ZERAR / TARA DO GANCHO",
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF030712),
                                side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _abrirModalSincronizacao(context),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_sync_rounded, color: Color(0xFF10B981), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "SINCRONIZAR / EXPORTAR",
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 24),
                                  SizedBox(width: 4),
                                  Text(
                                    "INICIAR PESAGEM",
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                                  ),
                                ],
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
