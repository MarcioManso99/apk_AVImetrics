import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/batch_metrics.dart';
import '../models/weighing_record.dart';

class ExportService {
  static Future<void> exportAndShareExcel({
    required List<WeighingRecord> records,
    required BatchMetrics metrics,
    String galpao = '01',
    String lote = 'Todos',
  }) async {
    if (records.isEmpty) {
      throw Exception('Não há pesagens para exportação.');
    }

    final excel = Excel.createExcel();
    final Sheet summarySheet = excel['Resumo Zootécnico JJ Agro'];
    excel.setDefaultSheet('Resumo Zootécnico JJ Agro');

    summarySheet.appendRow([
      TextCellValue('JJ AGRO - PRODUTOS AGROPECUÁRIOS & ASSISTÊNCIA TÉCNICA')
    ]);
    summarySheet.appendRow([
      TextCellValue('RELATÓRIO DE PESAGEM AVÍCOLA INDUSTRIAL')
    ]);
    summarySheet.appendRow([
      TextCellValue('Data de Emissão:'),
      TextCellValue(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()))
    ]);
    summarySheet.appendRow([TextCellValue('Galpão:'), TextCellValue(galpao)]);
    summarySheet.appendRow([TextCellValue('Gaiola/Sub-Lote:'), TextCellValue(lote)]);
    summarySheet.appendRow([TextCellValue('')]);

    summarySheet.appendRow([
      TextCellValue('INDICADOR ZOOTÉCNICO'),
      TextCellValue('VALOR'),
      TextCellValue('STATUS')
    ]);

    summarySheet.appendRow([
      TextCellValue('Total de Aves Pesadas'),
      IntCellValue(metrics.totalAves),
      TextCellValue('aves')
    ]);
    summarySheet.appendRow([
      TextCellValue('Peso Total Acumulado'),
      DoubleCellValue(metrics.pesoTotal),
      TextCellValue('kg')
    ]);
    summarySheet.appendRow([
      TextCellValue('Peso Médio do Lote'),
      DoubleCellValue(double.parse(metrics.pesoMedio.toStringAsFixed(3))),
      TextCellValue('kg')
    ]);
    summarySheet.appendRow([
      TextCellValue('Faixa Ideal (±10% da Média)'),
      TextCellValue('${metrics.limiteInferior.toStringAsFixed(2)} kg a ${metrics.limiteSuperior.toStringAsFixed(2)} kg'),
      TextCellValue('Ótimo')
    ]);
    summarySheet.appendRow([
      TextCellValue('Uniformidade do Lote'),
      TextCellValue('${metrics.uniformidadePercentual.toStringAsFixed(1)}%'),
      TextCellValue(metrics.uniformidadePercentual >= 80 ? 'Excelente (≥80%)' : 'Abaixo (<80%)')
    ]);
    summarySheet.appendRow([
      TextCellValue('Coeficiente de Variação (CV)'),
      TextCellValue('${metrics.coeficienteVariacao.toStringAsFixed(2)}%'),
      TextCellValue(metrics.coeficienteVariacao < 8 ? 'Excelente (<8%)' : 'Aceitável')
    ]);

    final Sheet detailSheet = excel['Pesagens Detalhadas'];
    detailSheet.appendRow([
      TextCellValue('Nº'),
      TextCellValue('GALPÃO'),
      TextCellValue('GAIOLA'),
      TextCellValue('PESO (KG)'),
      TextCellValue('DATA'),
      TextCellValue('HORA'),
      TextCellValue('MODO')
    ]);

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      detailSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(r.galpao),
        TextCellValue(r.gaiola),
        DoubleCellValue(r.peso),
        TextCellValue(r.data),
        TextCellValue(r.hora),
        TextCellValue(r.isAutoRecorded ? 'Auto' : 'Manual'),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final dateFile = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final filePath = '${tempDir.path}/JJAgro_Pesagem_${dateFile}_Galpao$galpao.xlsx';
    
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'JJ Agro - Relatório de Pesagem Galpão $galpao',
      text: 'Relatório zootécnico gerado pelo app JJ Agro Balança Avícola Pro (Galpão $galpao).',
    );
  }
}
