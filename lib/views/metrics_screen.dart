import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/weighing_controller.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeighingController>();
    final m = controller.metrics;

    return Scaffold(
      appBar: AppBar(
        title: Text('Métricas - Galpão ${controller.selectedGalpao}'),
      ),
      body: m.totalAves == 0
          ? const Center(
              child: Text(
                'Nenhuma pesagem realizada ainda neste galpão.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Destaque da Uniformidade
                  Card(
                    elevation: 3,
                    color: m.uniformidadePercentual >= 80 ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text('UNIFORMIDADE DO LOTE (±10%)', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Text(
                            '${m.uniformidadePercentual.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: m.uniformidadePercentual >= 80 ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                            ),
                          ),
                          Text(
                            '${m.avesNaFaixaIdeal} de ${m.totalAves} aves na faixa de ${m.limiteInferior.toStringAsFixed(2)}kg a ${m.limiteSuperior.toStringAsFixed(2)}kg',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Grade de 4 Métricas Zootécnicas
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMetricTile('Total de Aves', '${m.totalAves}', 'aves pesadas', Icons.pets, Colors.blue),
                      _buildMetricTile('Peso Médio', '${m.pesoMedio.toStringAsFixed(3)} kg', 'média real', Icons.scale, Colors.green),
                      _buildMetricTile('Peso Total', '${m.pesoTotal.toStringAsFixed(2)} kg', 'acumulado', Icons.fitness_center, Colors.teal),
                      _buildMetricTile('Coef. Variação (CV)', '${m.coeficienteVariacao.toStringAsFixed(1)}%', m.coeficienteVariacao < 8 ? 'Excelente (<8%)' : 'Aceitável', Icons.trending_up, Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Distribuição da População
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Distribuição Zootécnica das Aves', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          _buildDistributionRow('Abaixo do Peso (< -10%)', m.avesAbaixo, m.totalAves, Colors.amber),
                          const SizedBox(height: 8),
                          _buildDistributionRow('Faixa Ideal (±10%)', m.avesNaFaixaIdeal, m.totalAves, Colors.green),
                          const SizedBox(height: 8),
                          _buildDistributionRow('Acima do Peso (> +10%)', m.avesAcima, m.totalAves, Colors.redAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String label, int count, int total, Color color) {
    final double pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('$count aves (${(pct * 100).toStringAsFixed(1)}%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct,
          color: color,
          backgroundColor: Colors.grey.shade200,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
