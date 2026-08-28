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
      appBar: AppBar(
        title: const Text('Histórico de Pesagens'),
        actions: [
          IconButton(
            tooltip: 'Exportar Planilha Excel (.xlsx)',
            icon: const Icon(Icons.share),
            onPressed: controller.records.isEmpty
                ? null
                : () async {
                    try {
                      await ExportService.exportAndShareExcel(
                        records: controller.records,
                        metrics: controller.metrics,
                        galpao: controller.selectedGalpao,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao exportar: $e')),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Filtro e Exportação
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Galpão ${controller.selectedGalpao} (${controller.records.length} registros)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Gerar Excel'),
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
          ),

          // Lista de Registros
          Expanded(
            child: controller.records.isEmpty
                ? const Center(child: Text('Nenhum registro encontrado.'))
                : ListView.builder(
                    itemCount: controller.records.length,
                    itemBuilder: (context, index) {
                      final r = controller.records[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text('${r.peso.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('G${r.galpao} • Gaiola ${r.gaiola} • ${r.data} ${r.hora}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => controller.deleteRecord(r.id!),
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
