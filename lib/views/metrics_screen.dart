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
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: Text('Métricas Zootécnicas - Galpão ${controller.selectedGalpao}'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: m.totalAves == 0
          ? const Center(
              child: Text(
                'Nenhuma pesagem realizada ainda neste galpão.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Card Destaque de Uniformidade
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.4)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'UNIFORMIDADE DO LOTE (±10%)',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${m.uniformidadePercentual.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                          Text(
                            '${m.avesNaFaixaIdeal} de ${m.totalAves} aves na faixa ideal',
                            style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Grade de Métricas
                  Expanded(
                    flex: 6,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _buildTile('Total de Aves', '${m.totalAves} aves', Icons.pets, const Color(0xFFEA580C)),
                        _buildTile('Peso Médio', '${m.pesoMedio.toStringAsFixed(3)} kg', Icons.scale, Colors.orangeAccent),
                        _buildTile('Peso Total', '${m.pesoTotal.toStringAsFixed(2)} kg', Icons.fitness_center, Colors.amber),
                        _buildTile('Coef. Variação (CV)', '${m.coeficienteVariacao.toStringAsFixed(1)}%', Icons.trending_up, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}
