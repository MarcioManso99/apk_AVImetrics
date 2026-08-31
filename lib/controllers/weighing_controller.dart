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

  double _lastStableWeight = 0.0;
  final List<double> _weightHistory = [];
  bool _isWeightStable = true; // Por padrão estável
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

  Future<void> loadRecords() async {
    _records = await dbService.getAllRecords(galpao: selectedGalpao);
    _metrics = BatchMetrics.fromRecords(_records);
    notifyListeners();
  }

  void setGalpao(String galpao) {
    selectedGalpao = galpao;
    loadRecords();
  }

  void setGaiola(String gaiola) {
    selectedGaiola = gaiola;
    notifyListeners();
  }

  void toggleAutoRecord(bool value) {
    autoRecordEnabled = value;
    notifyListeners();
  }

  void _onBleDataReceived() {
    final currentWeight = bleService.currentWeight;
    
    _weightHistory.add(currentWeight);
    if (_weightHistory.length > 5) {
      _weightHistory.removeAt(0);
    }

    if (_weightHistory.length >= 4 && currentWeight >= 0.30) {
      double minW = _weightHistory.reduce((a, b) => a < b ? a : b);
      double maxW = _weightHistory.reduce((a, b) => a > b ? a : b);

      if ((maxW - minW) <= 0.03) {
        _isWeightStable = true;

        if (autoRecordEnabled) {
          final now = DateTime.now();
          final canAutoRecord = _lastAutoRecordTime == null ||
              now.difference(_lastAutoRecordTime!).inSeconds >= 3;

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
      _isWeightStable = currentWeight < 0.30;
    }

    notifyListeners();
  }

  Future<void> recordCurrentWeight({bool isAuto = false}) async {
    final double weightToSave = bleService.currentWeight;
    if (weightToSave <= 0.05) return;

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

  Future<void> deleteRecord(int id) async {
    await dbService.deleteRecord(id);
    await loadRecords();
  }

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
