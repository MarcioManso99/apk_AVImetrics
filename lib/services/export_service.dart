import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/batch_metrics.dart';
import '../models/weighing_record.dart';

class ExportService {
  /// Gera planilha Excel completa com aba de Resumo Zootécnico e Tabela Detalhada
  static Future<void> exportAndShareExcel({
    required List<WeighingRecord> records,
    required BatchMetrics metrics,
    String galpao = 'Todos',
    String lote = 'Todos',
  }) async {
    if (records.isEmpty) {
      throw Exception('Não há pesagens cadastradas para exportação.');
    }

    final excel = Excel.createExcel();
    
    // 1. Aba: Resumo Zootécnico
    final Sheet summarySheet = excel['Resumo Zootécnico'];
    excel.setDefaultSheet('Resumo Zootécnico');

    // Cabeçalho Principal
    summarySheet.appendRow([
      TextCellValue('BALANÇA AVÍCOLA PRO - RELATÓRIO ZOOTÉCNICO INDUSTRIAL')
    ]);
    summarySheet.appendRow([
      TextCellValue('Data de Emissão:'),
      TextCellValue(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()))
    ]);
    summarySheet.appendRow([TextCellValue('Galpão Selecionado:'), TextCellValue(galpao)]);
    summarySheet.appendRow([TextCellValue('Gaiola / Lote:'), TextCellValue(lote)]);
    summarySheet.appendRow([TextCellValue('')]);

    // Tabela de Indicadores
    summarySheet.appendRow([
      TextCellValue('INDICADOR ZOOTÉCNICO'),
      TextCellValue('VALOR'),
      TextCellValue('UNIDADE / STATUS')
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
      TextCellValue('ótimo')
    ]);
    summarySheet.appendRow([
      TextCellValue('Uniformidade do Lote'),
      TextCellValue('${metrics.uniformidadePercentual.toStringAsFixed(1)}%'),
      TextCellValue(metrics.uniformidadePercentual >= 80 ? 'Excelente (≥80%)' : 'Abaixo do Ideal (<80%)')
    ]);
    summarySheet.appendRow([
      TextCellValue('Aves na Faixa Ideal (±10%)'),
      IntCellValue(metrics.avesNaFaixaIdeal),
      TextCellValue('${((metrics.avesNaFaixaIdeal / (metrics.totalAves > 0 ? metrics.totalAves : 1)) * 100).toStringAsFixed(1)}%')
    ]);
    summarySheet.appendRow([
      TextCellValue('Aves Abaixo (< -10%)'),
      IntCellValue(metrics.avesAbaixo),
      TextCellValue('${((metrics.avesAbaixo / (metrics.totalAves > 0 ? metrics.totalAves : 1)) * 100).toStringAsFixed(1)}%')
    ]);
    summarySheet.appendRow([
      TextCellValue('Aves Acima (> +10%)'),
      IntCellValue(metrics.avesAcima),
      TextCellValue('${((metrics.avesAcima / (metrics.totalAves > 0 ? metrics.totalAves : 1)) * 100).toStringAsFixed(1)}%')
    ]);
    summarySheet.appendRow([
      TextCellValue('Peso Mínimo'),
      DoubleCellValue(metrics.pesoMin),
      TextCellValue('kg')
    ]);
    summarySheet.appendRow([
      TextCellValue('Peso Máximo'),
      DoubleCellValue(metrics.pesoMax),
      TextCellValue('kg')
    ]);
    summarySheet.appendRow([
      TextCellValue('Desvio Padrão'),
      DoubleCellValue(double.parse(metrics.desvioPadrao.toStringAsFixed(3))),
      TextCellValue('kg')
    ]);
    summarySheet.appendRow([
      TextCellValue('Coeficiente de Variação (CV)'),
      TextCellValue('${metrics.coeficienteVariacao.toStringAsFixed(2)}%'),
      TextCellValue(metrics.coeficienteVariacao < 8 ? 'Excelente (<8%)' : 'Aceitável (8-10%)')
    ]);

    // 2. Aba: Pesagens Detalhadas
    final Sheet detailSheet = excel['Pesagens Detalhadas'];
    detailSheet.appendRow([
      TextCellValue('Nº'),
      TextCellValue('GALPÃO'),
      TextCellValue('GAIOLA/LOTE'),
      TextCellValue('PESO (KG)'),
      TextCellValue('DATA'),
      TextCellValue('HORA'),
      TextCellValue('STATUS ZOOTÉCNICO'),
      TextCellValue('MODO')
    ]);

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      String status = 'Ideal (±10%)';
      if (metrics.pesoMedio > 0) {
        if (r.peso < metrics.limiteInferior) status = 'Abaixo (< -10%)';
        if (r.peso > metrics.limiteSuperior) status = 'Acima (> +10%)';
      }

      detailSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(r.galpao),
        TextCellValue(r.gaiola),
        DoubleCellValue(r.peso),
        TextCellValue(r.data),
        TextCellValue(r.hora),
        TextCellValue(status),
        TextCellValue(r.isAutoRecorded ? 'Auto' : 'Manual'),
      ]);
    }

    // Salvar arquivo em diretório temporário e compartilhar
    final bytes = excel.encode();
    if (bytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final dateFile = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final filePath = '${tempDir.path}/Pesagem_Avicola_${dateFile}_G$galpao.xlsx';
    
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // Disparar compartilhamento nativo (WhatsApp, E-mail, Drive)
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Relatório de Pesagem Avícola - Galpão $galpao',
      text: 'Segue em anexo o relatório zootécnico e planilha detalhada de pesagem do Galpão $galpao (${records.length} aves pesadas).',
    );
  }
}
