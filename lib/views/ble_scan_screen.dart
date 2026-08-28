import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class BleScanScreen extends StatelessWidget {
  const BleScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conexão Bluetooth (ESP32)'),
        actions: [
          if (ble.isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Escanear',
              onPressed: () => ble.startScan(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(16),
            color: ble.isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            child: Row(
              children: [
                Icon(
                  ble.isConnected ? Icons.check_circle : Icons.bluetooth_searching,
                  color: ble.isConnected ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ble.isConnected
                            ? 'Balança Conectada (${ble.connectedDevice?.platformName ?? 'ESP32'})'
                            : 'Balança Desconectada',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (ble.statusMessage != null)
                        Text(ble.statusMessage!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                if (ble.isConnected)
                  TextButton(
                    onPressed: () => ble.disconnect(),
                    child: const Text('DESCONECTAR', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),

          // Ações Rápidas de Tara quando conectado
          if (ble.isConnected)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.line_weight),
                label: const Text('Zerar Balança / Tara Remota'),
                onPressed: () => ble.sendTareCommand(),
              ),
            ),

          const Divider(height: 1),

          // Lista de Dispositivos Encontrados
          Expanded(
            child: ble.scanResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bluetooth, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Nenhuma balança encontrada.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar Balanças ESP32'),
                          onPressed: () => ble.startScan(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: ble.scanResults.length,
                    itemBuilder: (context, index) {
                      final result = ble.scanResults[index];
                      final name = result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : 'Dispositivo BLE (${result.device.remoteId})';

                      return ListTile(
                        leading: const Icon(Icons.scale, color: Color(0xFF1B5E20)),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('RSSI: ${result.rssi} dBm | ID: ${result.device.remoteId}'),
                        trailing: ElevatedButton(
                          child: const Text('Conectar'),
                          onPressed: () => ble.connectToDevice(result.device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
