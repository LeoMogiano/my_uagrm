import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sig_grupL/models/ubicaciones.dart';

class UbiService extends ChangeNotifier {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? '';
  List<Ubicaciones> ubicaciones = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading; // Getter para obtener el valor de isLoading

  UbiService() {
    getUbicaciones();
  }

  Future<List<Ubicaciones>> getUbicaciones() async {
    _isLoading = true; // Actualiza el valor de isLoading a true
    notifyListeners();

    try {
      final url = '$_baseUrl/api/places';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<Ubicaciones> tempUbis =
            Ubicaciones.parseUbicaciones(response.body);

        ubicaciones = tempUbis;
        return tempUbis;
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Error en cargar los datos de ubicaciones');
      }
    } catch (e) {
      // Manejar cualquier excepción que pueda ocurrir

      throw Exception('Error en cargar los datos de ubicaciones');
    } finally {
      _isLoading = false; // Actualiza el valor de isLoading a false
      notifyListeners();
    }
  }
}
