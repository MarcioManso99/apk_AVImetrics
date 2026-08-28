import 'package:intl/intl.dart';

class WeighingRecord {
  final int? id;
  final String galpao;
  final String gaiola;
  final double peso;
  final String data;
  final String hora;
  final int timestamp;
  final bool isAutoRecorded;

  WeighingRecord({
    this.id,
    required this.galpao,
    required this.gaiola,
    required this.peso,
    required this.data,
    required this.hora,
    required this.timestamp,
    this.isAutoRecorded = false,
  });

  /// Converte para Map para salvar no SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'galpao': galpao,
      'gaiola': gaiola,
      'peso': peso,
      'data': data,
      'hora': hora,
      'timestamp': timestamp,
      'isAutoRecorded': isAutoRecorded ? 1 : 0,
    };
  }

  /// Constrói a partir de um registro do SQLite
  factory WeighingRecord.fromMap(Map<String, dynamic> map) {
    return WeighingRecord(
      id: map['id'] as int?,
      galpao: map['galpao'] as String? ?? '01',
      gaiola: map['gaiola'] as String? ?? '01',
      peso: (map['peso'] as num).toDouble(),
      data: map['data'] as String,
      hora: map['hora'] as String,
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isAutoRecorded: (map['isAutoRecorded'] as int? ?? 0) == 1,
    );
  }

  /// Faz o parse seguro da string BLE recebida do ESP32:
  /// Formato: "GALPAO:01;GAIOLA:03;PESO:2.45;DATA:12/01/2026;HORA:08:34"
  factory WeighingRecord.fromBleString(String rawBleString, {
    String? defaultGalpao,
    String? defaultGaiola,
    bool isAuto = false,
  }) {
    String g = defaultGalpao ?? '01';
    String c = defaultGaiola ?? '01';
    double p = 0.0;
    
    final now = DateTime.now();
    String d = DateFormat('dd/MM/yyyy').format(now);
    String h = DateFormat('HH:mm').format(now);

    final parts = rawBleString.trim().split(';');
    for (var part in parts) {
      final kv = part.split(':');
      if (kv.length >= 2) {
        final key = kv[0].trim().toUpperCase();
        final value = kv[1].trim();

        if (key == 'GALPAO' || key == 'GALPÃO') {
          g = value;
        } else if (key == 'GAIOLA' || key == 'LOTE') {
          c = value;
        } else if (key == 'PESO') {
          p = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
        } else if (key == 'DATA') {
          d = value;
        } else if (key == 'HORA') {
          h = value;
        }
      }
    }

    return WeighingRecord(
      galpao: g,
      gaiola: c,
      peso: p,
      data: d,
      hora: h,
      timestamp: now.millisecondsSinceEpoch,
      isAutoRecorded: isAuto,
    );
  }

  WeighingRecord copyWith({
    int? id,
    String? galpao,
    String? gaiola,
    double? peso,
    String? data,
    String? hora,
    int? timestamp,
    bool? isAutoRecorded,
  }) {
    return WeighingRecord(
      id: id ?? this.id,
      galpao: galpao ?? this.galpao,
      gaiola: gaiola ?? this.gaiola,
      peso: peso ?? this.peso,
      data: data ?? this.data,
      hora: hora ?? this.hora,
      timestamp: timestamp ?? this.timestamp,
      isAutoRecorded: isAutoRecorded ?? this.isAutoRecorded,
    );
  }
}
