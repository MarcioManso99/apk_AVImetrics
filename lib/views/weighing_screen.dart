import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/weighing_controller.dart';
import '../services/ble_service.dart';

class WeighingScreen extends StatelessWidget {
  const WeighingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeighingController>();
    final ble = context.watch<BleService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balança Avícola Pro'),
        actions: [
          IconButton(
            tooltip: 'Comando de Tara / Zerar',
            icon: const Icon(Icons.refresh),
            onPressed: ble.isConnected
                ? () async {
                    await ble.sendTareCommand();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comando de Tara enviado ao ESP32')),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seletor de Galpão e Gaiola
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: controller.selectedGalpao,
                        decoration: const InputDecoration(
                          labelText: 'Galpão',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: ['01', '02', '03', '04', '05', '06']
                            .map((g) => DropdownMenuItem(value: g, child: Text('Galpão $g')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) controller.setGalpao(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: controller.selectedGaiola,
                        decoration: const InputDecoration(
                          labelText: 'Gaiola/Lote',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: ['01', '02', '03', '04', '05', '06', '07', '08']
                            .map((g) => DropdownMenuItem(value: g, child: Text('Gaiola $g')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) controller.setGaiola(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mostrador Digital em Destaque (Display LED Industrial)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: controller.isWeightStable ? const Color(0xFF10B981) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                          const SizedBox(width: 6),
                          Text(
                            ble.isConnected ? 'BLE ATIVO' : 'DESCONECTADO',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: controller.isWeightStable ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          controller.isWeightStable ? '● ESTÁVEL' : '○ OSCILANDO',
                          style: TextStyle(
                            color: controller.isWeightStable ? const Color(0xFF10B981) : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ble.currentWeight.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Text(
                    'QUILOGRAMAS (KG)',
                    style: TextStyle(color: Colors.white60, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Chave de Gravação Automática
            SwitchListTile(
              title: const Text('Gravação Automática ao Estabilizar', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Registra automaticamente quando o peso estabilizar por > 1s'),
              value: controller.autoRecordEnabled,
              activeColor: theme.colorScheme.primary,
              onChanged: controller.toggleAutoRecord,
            ),

            const SizedBox(height: 8),

            // Botão Principal de Registro Manual
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_task, size: 24),
              label: const Text('REGISTRAR PESAGEM MANUAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => controller.recordCurrentWeight(isAuto: false),
            ),

            const SizedBox(height: 20),

            // Resumo Rápido das Últimas Pesagens
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Últimas Pesagens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${controller.records.length} registradas', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.records.take(5).length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = controller.records[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text('#${index + 1}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('${r.peso.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('G${r.galpao} / Gaiola ${r.gaiola} • ${r.hora}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.deleteRecord(r.id!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
