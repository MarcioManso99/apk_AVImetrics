import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/weighing_controller.dart';
import '../services/export_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeighingController>();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: Text('Histórico - Galpão ${controller.selectedGalpao}'),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            tooltip: 'Exportar para Excel (.xlsx)',
            icon: const Icon(Icons.share, color: Color(0xFFEA580C)),
            onPressed: controller.records.isEmpty
                ? null
                : () => ExportService.exportAndShareExcel(
                      records: controller.records,
                      metrics: controller.metrics,
                      galpao: controller.selectedGalpao,
                    ),
          ),
        ],
      ),
      body: controller.records.isEmpty
          ? const Center(child: Text('Nenhuma pesagem gravada.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.records.length,
              itemBuilder: (context, index) {
                final r = controller.records[index];
                return Card(
                  color: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${r.peso.toStringAsFixed(2)} kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('G${r.galpao} • Gaiola ${r.gaiola} • ${r.data} ${r.hora}', style: const TextStyle(color: Colors.white54)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => controller.deleteRecord(r.id!),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
