import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/batch_metrics.dart';
import '../models/weighing_record.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';

class WeighingController extends ChangeNotifier {
  final BleService bleService;
  final DatabaseService dbService;

  String selectedGalpao = "01";
  String selectedGaiola = "01";
  bool autoRecordEnabled = true;

  List<WeighingRecord> _records = [];
  BatchMetrics _metrics = BatchMetrics.empty();

  // Algoritmo de Detecção de Estabilidade de Peso (Filtro de Amortecimento)
  double _lastStableWeight = 0.0;
  final List<double> _weightHistory = [];
  bool _isWeightStable = false;
  DateTime? _lastAutoRecordTime;

  List<WeighingRecord> get records => _records;
  BatchMetrics get metrics => _metrics;
  bool get isWeightStable => _isWeightStable;

  WeighingController({
    required this.bleService,
    required this.dbService,
  }) {
    _init();
  }

  void _init() {
    loadRecords();
    bleService.addListener(_onBleDataReceived);
  }

  /// Carrega pesagens do SQLite e recalcula métricas
  Future<void> loadRecords() async {
    _records = await dbService.getAllRecords(galpao: selectedGalpao);
    _metrics = BatchMetrics.fromRecords(_records);
    notifyListeners();
  }

  /// Altera o galpão ativo
  void setGalpao(String galpao) {
    selectedGalpao = galpao;
    loadRecords();
  }

  /// Altera a gaiola ativa
  void setGaiola(String gaiola) {
    selectedGaiola = gaiola;
    notifyListeners();
  }

  /// Liga/Desliga gravação automática por estabilidade
  void toggleAutoRecord(bool value) {
    autoRecordEnabled = value;
    notifyListeners();
  }

  /// Trata dados recebidos da balança e verifica estabilização
  void _onBleDataReceived() {
    final currentWeight = bleService.currentWeight;
    
    _weightHistory.add(currentWeight);
    if (_weightHistory.length > 5) {
      _weightHistory.removeAt(0);
    }

    // Critério de Estabilidade: Variação máxima < 0.02 kg nos últimos 5 frames e peso > 0.30 kg (ave no gancho)
    if (_weightHistory.length >= 5 && currentWeight >= 0.30) {
      double minW = _weightHistory.reduce((a, b) => a < b ? a : b);
      double maxW = _weightHistory.reduce((a, b) => a > b ? a : b);

      if ((maxW - minW) <= 0.03) {
        _isWeightStable = true;

        // Auto-gravação se habilitada e após intervalo mínimo de 2 segundos entre aves
        if (autoRecordEnabled) {
          final now = DateTime.now();
          final canAutoRecord = _lastAutoRecordTime == null ||
              now.difference(_lastAutoRecordTime!).inSeconds >= 3;

          // Deve ser um peso diferente do último registrado para evitar duplicidade
          if (canAutoRecord && (currentWeight - _lastStableWeight).abs() > 0.05) {
            _lastStableWeight = currentWeight;
            _lastAutoRecordTime = now;
            recordCurrentWeight(isAuto: true);
          }
        }
      } else {
        _isWeightStable = false;
      }
    } else {
      _isWeightStable = false;
    }

    notifyListeners();
  }

  /// Registra pesagem (manual ou automática)
  Future<void> recordCurrentWeight({bool isAuto = false}) async {
    final double weightToSave = bleService.currentWeight;
    if (weightToSave <= 0.05) return; // Não salvar peso vazio

    // Tentar criar a partir da string raw se contiver os dados exatos do ESP32
    final record = WeighingRecord.fromBleString(
      bleService.latestRawData,
      defaultGalpao: selectedGalpao,
      defaultGaiola: selectedGaiola,
      isAuto: isAuto,
    ).copyWith(
      galpao: selectedGalpao,
      gaiola: selectedGaiola,
      peso: weightToSave,
    );

    await dbService.insertRecord(record);
    await loadRecords();
  }

  /// Deleta um registro específico
  Future<void> deleteRecord(int id) async {
    await dbService.deleteRecord(id);
    await loadRecords();
  }

  /// Limpa todos os registros do galpão
  Future<void> clearAll() async {
    await dbService.clearRecords(galpao: selectedGalpao);
    await loadRecords();
  }

  @override
  void dispose() {
    bleService.removeListener(_onBleDataReceived);
    super.dispose();
  }
}
