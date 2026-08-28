import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService extends ChangeNotifier {
  // UUIDs padrão para Balança com ESP32
  static const String scaleServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String scaleCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String tareCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  BluetoothCharacteristic? _tareCharacteristic;

  bool _isScanning = false;
  bool _isConnected = false;
  List<ScanResult> _scanResults = [];
  String _latestRawData = "";
  double _currentWeight = 0.0;
  String? _statusMessage;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _charSub;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  List<ScanResult> get scanResults => _scanResults;
  String get latestRawData => _latestRawData;
  double get currentWeight => _currentWeight;
  String? get statusMessage => _statusMessage;

  BleService() {
    _initBleListener();
  }

  void _initBleListener() {
    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });
  }

  /// Inicia o escaneamento de balanças ESP32 próximas
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return;
    
    _scanResults.clear();
    _statusMessage = "Procurando balanças BLE...";
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results;
        notifyListeners();
      });
    } catch (e) {
      _statusMessage = "Erro ao escanear: $e";
      notifyListeners();
    }
  }

  /// Para o escaneamento
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  /// Conecta à balança selecionada
  Future<bool> connectToDevice(BluetoothDevice device) async {
    _statusMessage = "Conectando a ${device.platformName.isNotEmpty ? device.platformName : 'ESP32 Balança'}...";
    notifyListeners();

    try {
      await stopScan();
      await device.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      _connectedDevice = device;
      _isConnected = true;

      _connSub = device.connectionState.listen((state) {
        _isConnected = state == BluetoothConnectionState.connected;
        if (!_isConnected) {
          _statusMessage = "Dispositivo desconectado.";
          _connectedDevice = null;
        }
        notifyListeners();
      });

      // Descobrir Serviços e Características
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify || char.properties.read) {
            _dataCharacteristic = char;
            await _subscribeToCharacteristic(char);
          }
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _tareCharacteristic = char;
          }
        }
      }

      _statusMessage = "Conectado com sucesso!";
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = "Falha ao conectar: $e";
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Escuta a string contínua de pesagem enviada pelo ESP32
  Future<void> _subscribeToCharacteristic(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    _charSub?.cancel();
    _charSub = characteristic.onValueReceived.listen((value) {
      final rawStr = utf8.decode(value, allowMalformed: true).trim();
      if (rawStr.isNotEmpty) {
        _latestRawData = rawStr;
        _parseCurrentWeight(rawStr);
        notifyListeners();
      }
    });
  }

  /// Extrai o peso atual numérico para exibição em tempo real
  void _parseCurrentWeight(String raw) {
    try {
      final parts = raw.split(';');
      for (var p in parts) {
        if (p.toUpperCase().startsWith('PESO:')) {
          final val = p.substring(5).replaceAll(',', '.').trim();
          final parsed = double.tryParse(val);
          if (parsed != null) {
            _currentWeight = parsed;
          }
        }
      }
    } catch (_) {}
  }

  /// Envia comando de TARA / ZERAR para o ESP32
  Future<bool> sendTareCommand() async {
    if (_tareCharacteristic == null && _dataCharacteristic == null) return false;
    try {
      final target = _tareCharacteristic ?? _dataCharacteristic!;
      await target.write(utf8.encode("CMD:TARE\n"), withoutResponse: false);
      _statusMessage = "Comando de Tara enviado com sucesso.";
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = "Erro ao enviar Tara: $e";
      notifyListeners();
      return false;
    }
  }

  /// Desconectar
  Future<void> disconnect() async {
    _charSub?.cancel();
    _connSub?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _connectedDevice = null;
    _isConnected = false;
    _statusMessage = "Desconectado.";
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _charSub?.cancel();
    super.dispose();
  }
}
