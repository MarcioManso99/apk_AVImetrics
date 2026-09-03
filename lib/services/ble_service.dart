import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BleService extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;

  bool _isConnecting = false;
  bool _isConnected = false;
  List<BluetoothDevice> _pairedDevices = [];
  String _latestRawData = "PESO:0.00;";
  double _currentWeight = 0.00;
  String? _statusMessage;
  String _buffer = '';

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isConnecting;
  bool get isConnected => _isConnected;
  List<BluetoothDevice> get scanResults => _pairedDevices;
  String get latestRawData => _latestRawData;
  double get currentWeight => _currentWeight;
  String? get statusMessage => _statusMessage;

  BleService() {
    loadPairedDevices();
  }

  // Lista os dispositivos salvos/pareados nas configurações do Android
  Future<void> loadPairedDevices() async {
    try {
      _pairedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      notifyListeners();
    } catch (e) {
      _statusMessage = "Erro ao buscar pareados: $e";
      notifyListeners();
    }
  }

  // Método compatível com o startScan anterior
  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    _statusMessage = "Buscando balanças pareadas...";
    notifyListeners();
    await loadPairedDevices();
    
    // Tenta autoconectar se encontrar AVImetrics_Scale
    for (var d in _pairedDevices) {
      if ((d.name ?? '').contains('AVImetrics')) {
        await connectToDevice(d);
        break;
      }
    }
  }

  Future<void> stopScan() async {
    _isConnecting = false;
    notifyListeners();
  }

  // Conecta diretamente ao dispositivo selecionado
  Future<bool> connectToDevice(BluetoothDevice device) async {
    _isConnecting = true;
    _statusMessage = "Conectando a ${device.name ?? 'Balança'}...";
    notifyListeners();

    try {
      await disconnect();

      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _isConnected = true;
      _isConnecting = false;
      _statusMessage = "Conectado a ${device.name}!";
      notifyListeners();

      // Escuta os dados seriais recebidos do ESP32
      _connection!.input?.listen((Uint8List data) {
        _buffer += ascii.decode(data);
        if (_buffer.contains('\n')) {
          List<String> lines = _buffer.split('\n');
          for (int i = 0; i < lines.length - 1; i++) {
            String line = lines[i].trim();
            if (line.isNotEmpty) {
              _latestRawData = line;
              _parseCurrentWeight(line);
            }
          }
          _buffer = lines.last;
          notifyListeners();
        }
      }).onDone(() {
        _isConnected = false;
        _connectedDevice = null;
        _statusMessage = "Balança desconectada.";
        notifyListeners();
      });

      return true;
    } catch (e) {
      _statusMessage = "Falha ao conectar: $e";
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

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

  // Envia comando de TARA via porta serial
  Future<bool> sendTareCommand() async {
    if (_connection != null && _connection!.isConnected) {
      try {
        _connection!.output.add(ascii.encode("CMD:TARE\n"));
        await _connection!.output.allSent;
        _currentWeight = 0.0;
        _statusMessage = "Gancho zerado com sucesso (Tara executada).";
        notifyListeners();
        return true;
      } catch (e) {
        _statusMessage = "Erro ao enviar tara: $e";
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.finish();
      _connection = null;
    }
    _connectedDevice = null;
    _isConnected = false;
    _statusMessage = "Desconectado.";
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
