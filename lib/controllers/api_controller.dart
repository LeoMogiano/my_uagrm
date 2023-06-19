import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';


class ApiController {
  final String apiUrl = dotenv.env['API_BACKEND'] ?? '';

  Future<void> descargarYGuardarJSON() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      final jsonData = response.body;

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data.json');
      await file.writeAsString(jsonData);

      print('Archivo JSON descargado y guardado exitosamente');
    } catch (error) {
      print('Error al descargar y guardar el archivo JSON: $error');
    }
  }

  Future<List<Map<String, Object>>> leerJSON() async {
    try {
      await descargarYGuardarJSON();

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data.json');
      final jsonString = await file.readAsString();

      final jsonData = json.decode(jsonString);

      /* print("jsonData: $jsonData"); */

      if (jsonData is List<dynamic>) {
        final parsedData = jsonData
            .cast<Map<String, dynamic>>()
            .map((item) => item.map<String, Object>(
                  (key, value) => MapEntry<String, Object>(
                    key,
                    value ?? '', // Convierte los valores null en cadenas vacías
                  ),
                ))
            .toList();

        final List<Map<String, Object>> convertedData =
            List<Map<String, Object>>.from(parsedData);

        return convertedData;
      } else {
        throw Exception('El archivo JSON no tiene el formato esperado');
      }
    } catch (error) {
      throw Exception('Error al leer el archivo JSON: $error');
    }
  }
}
