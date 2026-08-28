import 'dart:math';
import 'weighing_record.dart';

class BatchMetrics {
  final int totalAves;
  final double pesoTotal;
  final double pesoMedio;
  final double pesoMin;
  final double pesoMax;
  final double desvioPadrao;
  final double coeficienteVariacao; // CV%
  final double uniformidadePercentual; // % de aves em ±10% da média
  final int avesNaFaixaIdeal;
  final int avesAbaixo;
  final int avesAcima;
  final double limiteInferior; // Média - 10%
  final double limiteSuperior; // Média + 10%

  BatchMetrics({
    required this.totalAves,
    required this.pesoTotal,
    required this.pesoMedio,
    required this.pesoMin,
    required this.pesoMax,
    required this.desvioPadrao,
    required this.coeficienteVariacao,
    required this.uniformidadePercentual,
    required this.avesNaFaixaIdeal,
    required this.avesAbaixo,
    required this.avesAcima,
    required this.limiteInferior,
    required this.limiteSuperior,
  });

  factory BatchMetrics.empty() {
    return BatchMetrics(
      totalAves: 0,
      pesoTotal: 0.0,
      pesoMedio: 0.0,
      pesoMin: 0.0,
      pesoMax: 0.0,
      desvioPadrao: 0.0,
      coeficienteVariacao: 0.0,
      uniformidadePercentual: 0.0,
      avesNaFaixaIdeal: 0,
      avesAbaixo: 0,
      avesAcima: 0,
      limiteInferior: 0.0,
      limiteSuperior: 0.0,
    );
  }

  /// Processa a lista de pesagens e calcula os parâmetros zootécnicos reais
  factory BatchMetrics.fromRecords(List<WeighingRecord> records) {
    if (records.isEmpty) return BatchMetrics.empty();

    final pesos = records.map((r) => r.peso).toList();
    final int total = pesos.length;
    final double somaTotal = pesos.reduce((a, b) => a + b);
    final double media = somaTotal / total;

    final double minP = pesos.reduce(min);
    final double maxP = pesos.reduce(max);

    // Desvio Padrão Amostral
    double variance = 0.0;
    if (total > 1) {
      double sumSquares = 0.0;
      for (var p in pesos) {
        sumSquares += pow(p - media, 2);
      }
      variance = sumSquares / (total - 1);
    }
    final double dp = sqrt(variance);

    // Coeficiente de Variação (CV%)
    final double cv = media > 0 ? (dp / media) * 100.0 : 0.0;

    // Faixa de ±10% da média zootécnica
    final double limInf = media * 0.90;
    final double limSup = media * 1.10;

    int ideais = 0;
    int abaixo = 0;
    int acima = 0;

    for (var p in pesos) {
      if (p < limInf) {
        abaixo++;
      } else if (p > limSup) {
        acima++;
      } else {
        ideais++;
      }
    }

    final double uniformidade = total > 0 ? (ideais / total) * 100.0 : 0.0;

    return BatchMetrics(
      totalAves: total,
      pesoTotal: somaTotal,
      pesoMedio: media,
      pesoMin: minP,
      pesoMax: maxP,
      desvioPadrao: dp,
      coeficienteVariacao: cv,
      uniformidadePercentual: uniformidade,
      avesNaFaixaIdeal: ideais,
      avesAbaixo: abaixo,
      avesAcima: acima,
      limiteInferior: limInf,
      limiteSuperior: limSup,
    );
  }
}
