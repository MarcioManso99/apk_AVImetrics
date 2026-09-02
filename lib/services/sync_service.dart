import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class SyncService {
  final DatabaseService dbService;

  SyncService({required this.dbService});

  /// Gera arquivo CSV e abre o seletor do Android (WhatsApp, Drive, Salvar)
  Future<bool> exportAndShareCsv(BuildContext context) async {
    try {
      final weighings = await dbService.getAllWeighings();
      if (weighings.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nenhuma pesagem gravada para exportar.")),
          );
        }
        return false;
      }

      // Cabeçalho CSV padrão compatível com Excel e Central Web
      final StringBuffer csv = StringBuffer();
      csv.writeln("ID;GALPAO;GAIOLA;PESO_KG;TIPO;DATA_HORA");

      for (final item in weighings) {
        final id = item['id'] ?? '';
        final galpao = item['galpao'] ?? '';
        final gaiola = item['gaiola'] ?? '';
        final peso = (item['weight'] ?? 0.0).toString();
        final tipo = (item['is_auto'] == 1) ? 'AUTOMATICO' : 'MANUAL';
        final data = item['timestamp'] ?? '';

        csv.writeln("$id;$galpao;$gaiola;$peso;$tipo;$data");
      }

      // Salva no diretório temporário do aparelho
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/AVImetrics_Pesagens_$dateStr.csv');
      await file.writeAsString(csv.toString(), encoding: utf8);

      // Abre compartilhamento
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Arquivo de Pesagem AVImetrics ($dateStr)',
        subject: 'Lote de Pesagens JJ Agro',
      );
      return true;
    } catch (e) {
      debugPrint("Erro ao exportar CSV: $e");
      return false;
    }
  }

  /// Envio manual via internet direto para o endpoint da Central
  Future<bool> sendDirectToCentral({
    required String endpointUrl,
    required String apiKey,
  }) async {
    try {
      final weighings = await dbService.getAllWeighings();
      if (weighings.isEmpty) return false;

      final payload = {
        "app": "AVImetrics",
        "data_envio": DateTime.now().toIso8601String(),
        "total_registros": weighings.length,
        "pesagens": weighings,
      };

      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(endpointUrl));
      request.headers.set('Content-Type', 'application/json; charset=UTF-8');
      if (apiKey.isNotEmpty) {
        request.headers.set('apikey', apiKey);
        request.headers.set('Authorization', 'Bearer $apiKey');
      }

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint("Erro ao conectar à Central: $e");
      return false;
    }
  }
}
