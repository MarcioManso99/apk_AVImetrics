import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  final String? galpaoFiltro;

  const HistoryScreen({super.key, this.galpaoFiltro});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _registros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarRegistros();
  }

  Future<void> _carregarRegistros() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> dados;

    if (widget.galpaoFiltro != null && widget.galpaoFiltro!.isNotEmpty) {
      dados = await db.query(
        'weighings',
        where: 'galpao = ?',
        whereArgs: [widget.galpaoFiltro],
        orderBy: 'id DESC',
      );
    } else {
      dados = await db.query('weighings', orderBy: 'id DESC');
    }

    setState(() {
      _registros = dados;
      _isLoading = false;
    });
  }

  Future<void> _confirmarExclusao(int id, double peso) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              "Apagar Registro?",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Deseja apagar a pesagem de ${peso.toStringAsFixed(3)} kg?\nEsta ação não poderá ser desfeita.",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("APAGAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseService.instance.deleteRecord(id);
      _carregarRegistros();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pesagem apagada com sucesso!"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  String _formatarDataHora(dynamic ts) {
    if (ts == null) return '-';
    try {
      if (ts is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        return DateFormat('HH:mm:ss - dd/MM').format(dt);
      }
      final str = ts.toString();
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        return DateFormat('HH:mm:ss - dd/MM').format(dt);
      }
      return str;
    } catch (_) {
      return ts.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPeso = 0.0;
    for (var r in _registros) {
      final p = (r['weight'] ?? r['peso'] ?? 0.0) as num;
      totalPeso += p.toDouble();
    }
    final media = _registros.isNotEmpty ? (totalPeso / _registros.length) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          widget.galpaoFiltro != null
              ? "HISTÓRICO - ${widget.galpaoFiltro}"
              : "HISTÓRICO GERAL DE PESAGENS",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEA580C)),
            onPressed: _carregarRegistros,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("TOTAL DE AVES", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${_registros.length}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Container(height: 24, width: 1, color: Colors.white12),
                  Column(
                    children: [
                      const Text("PESO MÉDIO", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${media.toStringAsFixed(3)} kg", style: const TextStyle(color: Color(0xFFEA580C), fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Container(height: 24, width: 1, color: Colors.white12),
                  Column(
                    children: [
                      const Text("PESO TOTAL", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${totalPeso.toStringAsFixed(2)} kg", style: const TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
                  : _registros.isEmpty
                      ? const Center(
                          child: Text(
                            "Nenhuma pesagem gravada.",
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _registros.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _registros[index];
                            final id = item['id'] as int;
                            final rawPeso = item['weight'] ?? item['peso'] ?? 0.0;
                            final peso = (rawPeso as num).toDouble();
                            final galpao = item['galpao']?.toString() ?? '-';
                            final gaiola = item['gaiola']?.toString() ?? '-';
                            final horaFormatada = _formatarDataHora(item['timestamp']);

                            final aveNumero = _registros.length - index;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF030712),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      "#$aveNumero",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$galpao | $gaiola",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          horaFormatada,
                                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${peso.toStringAsFixed(3)} kg",
                                    style: const TextStyle(
                                      color: Color(0xFFEA580C),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                    onPressed: () => _confirmarExclusao(id, peso),
                                    tooltip: "Apagar pesagem errada",
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
