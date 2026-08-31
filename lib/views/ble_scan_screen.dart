import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class BleScanScreen extends StatelessWidget {
  const BleScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Conectar Balança Bluetooth'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ble.startScan(),
          ),
        ],
      ),
      body: ble.scanResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_searching, size: 54, color: Color(0xFFEA580C)),
                  const SizedBox(height: 12),
                  const Text('Procurando balanças ESP32...', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                    onPressed: () => ble.startScan(),
                    child: const Text('Escanear Novamente', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ble.scanResults.length,
              itemBuilder: (context, index) {
                final res = ble.scanResults[index];
                final name = res.device.platformName.isNotEmpty ? res.device.platformName : 'Balança ESP32 (${res.device.remoteId})';
                return Card(
                  color: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.scale, color: Color(0xFFEA580C)),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Sinal RSSI: ${res.rssi} dBm', style: const TextStyle(color: Colors.white54)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                      child: const Text('Conectar', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final ok = await ble.connectToDevice(res.device);
                        if (ok && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
