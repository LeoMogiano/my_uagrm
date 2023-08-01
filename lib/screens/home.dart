import 'dart:async';
import 'dart:convert';

import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:location/location.dart';
import 'package:image/image.dart' as img;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:sig_grupL/models/autocomplate_prediction.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

/* import 'package:sig_grupL/controllers/api_controller.dart'; */
import 'package:sig_grupL/controllers/functions_map.dart';
import 'package:sig_grupL/models/ubicaciones.dart';
import 'package:sig_grupL/services/ubi_services.dart';
import 'package:sig_grupL/utils/utils.dart';
import 'package:sig_grupL/widgets/widgets.dart';

import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isListening = false;
  SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  final String selectedLocaleId = 'es_MX';
  final String apiGoogle = dotenv.env['API_GOOGLE'] ?? '';
  final Completer<GoogleMapController> _completer = Completer();
  LocationData? currentLocation;
  bool mostrarMarcador = true;
  Set<Marker> markers = {};

  List<LatLng> polylineCoordinates = [];
  double inicioLatitude = 0;
  double inicioLongitude = 0;
  bool finMarker = false;
  bool miUbicacion = false;
  bool noGoogle = false;
/*   bool findGoogle = false; */
  bool dosPuntos = false;
  bool bandera = false;

  String description = '';
  String group = '';
  String initials = '';
  double totalDistance = 0.0;
  String address = '';
  LatLng? iniLocation;
  bool isLoading = false;
  String tiempoCaminando = '';
  String tiempoAuto = '';

  TravelMode travelMode = TravelMode.driving; // Modo de viaje
  LatLng position = const LatLng(0, 0);
  bool areCalculationsDone = false; // Control de estado para los cálculos

  Set<Polyline> autoPolylines = {};
  Set<Polyline> walkingPolylines = {};

  List<Map<String, Object>> jsonData = [];
  List<Ubicaciones?> datosUbicacion = [];
  List<String?> datosGroup = [];
  List<AutocompletePrediction> placePredictionList = [];
  late UbiService ubiService;
  final TextEditingController _searchController = TextEditingController();
  final FloatingSearchBarController _searchBarController =
      FloatingSearchBarController();

  void startListening() async {
    var status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      var result = await Permission.microphone.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        // El usuario ha denegado el permiso o ha seleccionado "No volver a preguntar". Maneja este caso según tus necesidades.
        return;
      }
    }
    speechEnabled = await speechToText.initialize();

    setState(() {
      isListening = true;
    });

    debugPrint('Inicio del reconocimiento de voz');

    speechToText.listen(
      onResult: (result) {
        setState(() {
          _searchBarController.query = result.recognizedWords;
          _searchBarController.open();
          search(result.recognizedWords);
        });

        // Comprobar si se ha detectado un comando para detener el reconocimiento de voz
        if (result.finalResult) {
          stopListening();
        }
      },
      localeId: selectedLocaleId,
      cancelOnError: false,
    );
  }

  void stopListening() {
    setState(() {
      isListening = false;
    });

    debugPrint('Fin del reconocimiento de voz');

    speechToText.stop();
  }

  Ubicaciones? getUbicacionForItem(String item) {
    final ubicacion = ubiService.ubicaciones.firstWhere(
      (element) => element.description == item,
      orElse: () => Ubicaciones(description: '', group: '', location: ''),
    );

    return ubicacion;
  }

  String? getGroupForItem(String item) {
    final ubicacion = ubiService.ubicaciones.firstWhere(
      (element) => element.description == item,
      orElse: () => Ubicaciones(description: '', group: '', location: ''),
    );

    return ubicacion.group;
  }

  String? getLocationForItem(String item) {
    final ubicacion = ubiService.ubicaciones.firstWhere(
      (element) => element.description == item,
      orElse: () => Ubicaciones(description: '', group: '', location: ''),
    );

    return ubicacion.location;
  }

  Future<GoogleMapController> get _mapController async {
    return await _completer.future;
  }

  _init() async {
    (await _mapController).setMapStyle(jsonEncode(mapStyle));
  }

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then((LocationData locationData) {
      setState(() {
        currentLocation = locationData;
      });
    });
  }

  Future<LatLng> getLatLng(ScreenCoordinate screenCoordinate) async {
    final GoogleMapController controller = await _mapController;
    return controller.getLatLng(screenCoordinate);
  }

  void addMarker(LatLng position) async {
    if (bandera) {
      removeMarker(markers.last.markerId);
      bandera = false;
    }

    if (dosPuntos == false) {
      final ByteData imageData =
          await rootBundle.load('assets/icons/mark_start.png');
      final Uint8List bytes = imageData.buffer.asUint8List();
      final img.Image? originalImage = img.decodeImage(bytes);
      final img.Image resizedImage =
          img.copyResize(originalImage!, width: 88, height: 140);
      final resizedImageData = img.encodePng(resizedImage);
      final BitmapDescriptor bitmapDescriptor =
          BitmapDescriptor.fromBytes(resizedImageData);
      final newMarker = Marker(
        markerId: MarkerId(DateTime.now().millisecondsSinceEpoch.toString()),
        position: position,
        icon: bitmapDescriptor,
      );
      mostrarMarcador = true;
      /* if (miUbicacion) {
        final GoogleMapController controller = await _mapController;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                currentLocation!.latitude!,
                currentLocation!.longitude!,
              ),
              zoom: 14.5,
            ),
          ),
        );
      } */
      setState(() {
        markers.add(newMarker);
        if (dosPuntos) createPolylines(position);
      });
    } else {
      final ByteData imageData = await rootBundle.load('assets/icons/mark.png');
      final Uint8List bytes = imageData.buffer.asUint8List();
      final img.Image? originalImage = img.decodeImage(bytes);
      final img.Image resizedImage =
          img.copyResize(originalImage!, width: 88, height: 140);
      final resizedImageData = img.encodePng(resizedImage);
      final BitmapDescriptor bitmapDescriptor =
          BitmapDescriptor.fromBytes(resizedImageData);
      final newMarker = Marker(
        markerId: MarkerId(DateTime.now().millisecondsSinceEpoch.toString()),
        position: position,
        icon: bitmapDescriptor,
      );
      mostrarMarcador = true;
      /* if (miUbicacion) {
        final GoogleMapController controller = await _mapController;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                currentLocation!.latitude!,
                currentLocation!.longitude!,
              ),
              zoom: 14.5,
            ),
          ),
        );
      } */
      setState(() {
        markers.add(newMarker);
        if (dosPuntos) createPolylines(position);
      });
    }
  }

  void createPolylines(LatLng position) async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> newPolylineCoordinates =
        []; // Nuevas coordenadas de la polilínea

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiGoogle,
      PointLatLng(inicioLatitude, inicioLongitude),
      PointLatLng(position.latitude, position.longitude),
      travelMode: travelMode,
    );

    if (result.status == 'OK') {
      for (var point in result.points) {
        newPolylineCoordinates.add(LatLng(point.latitude, point.longitude));
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      // Actualiza las polilíneas según el modo de transporte seleccionado
      if (travelMode == TravelMode.driving) {
        autoPolylines = {
          Polyline(
            polylineId: const PolylineId('autoPolyline'),
            color: Colors.blue,
            points: newPolylineCoordinates,
            width: 5,
          ),
        };
      } else if (travelMode == TravelMode.walking) {
        walkingPolylines = {
          Polyline(
            polylineId: const PolylineId('walkingPolyline'),
            color: Colors.green,
            points: newPolylineCoordinates,
            width: 5,
          ),
        };
      }
      if (!areCalculationsDone) {
        // Realiza los cálculos solo si no se han realizado antes
        // Calcula la distancia nuevamente
        totalDistance = calculatePolylineDistance(polylineCoordinates);
        Map<String, String> tiempos = calculateTime(totalDistance);

        tiempoAuto = tiempos['tiempoAuto']!;
        tiempoCaminando = tiempos['tiempoCaminando']!;
        /* calculatePolylineDistance(polylineCoordinates); */

        // Actualiza el control de estado
        areCalculationsDone = true;
      }
    }

    // Obtén el GoogleMapController
    GoogleMapController controller = await _mapController;

    // Crea una lista de LatLng que contiene todos los puntos del polyline
    List<LatLng> allPoints = [
      LatLng(inicioLatitude, inicioLongitude),
      ...polylineCoordinates,
      LatLng(position.latitude, position.longitude),
    ];

    // Calcula los límites del polyline
    LatLngBounds bounds = boundsFromLatLngList(allPoints);

    // Ajusta la cámara para mostrar los límites del polyline en toda la pantalla
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            (bounds.northeast.latitude + bounds.southwest.latitude) / 2 - 0.006,
            (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
          ),
          zoom: 13.4,
        ),
      ),
    );

    bandera = true;

    setState(() {});
  }

  void removeMarker(MarkerId markerId) {
    setState(() {
      markers.removeWhere((marker) => marker.markerId == markerId);
      polylineCoordinates.clear();
      autoPolylines.clear();
      walkingPolylines.clear();
      areCalculationsDone = false;
      mostrarMarcador = true;
    });
  }

  Future<void> search(String query) async {
    if (miUbicacion == true && noGoogle == false) {
      Uri uri = Uri.https(
          "maps.googleapis.com", "/maps/api/place/autocomplete/json", {
        "input": "Santa Cruz de la Sierra $query",
        "key": apiGoogle,
        "language": "es",
        "components": "country:bo",
      });
      /* print(uri); */

      // Realizar la solicitud a la API de Place Autocomplete
      var response = await http.get(uri);
      if (response.statusCode == 200) {
        // Decodificar la respuesta JSON
        var data = json.decode(response.body);

        // Verificar si hay resultados
        if (data['status'] == 'OK' && data['predictions'].length > 0) {
          // Obtener el lugar sugerido (el primer resultado)

          setState(() {
            placePredictionList = (data['predictions'] as List)
                .map((item) => AutocompletePrediction.fromJson(item))
                .toList();
          });

          /* print(placePredictionList.length); */
          /* var place = data['predictions'][0];

          // Obtener el ID del lugar
          String placeId = place['place_id'];

          // Utilizar el ID del lugar para obtener detalles de geocoding
          Uri geocodingUri =
              Uri.https("maps.googleapis.com", "/maps/api/geocode/json", {
            "place_id": placeId,
            "key": apiGoogle,
          });

          // Realizar la solicitud a la API de Geocoding
          var geocodingResponse = await http.get(geocodingUri);
          if (geocodingResponse.statusCode == 200) {
            // Decodificar la respuesta JSON de Geocoding
            var geocodingData = json.decode(geocodingResponse.body);

            // Verificar si hay resultados
            if (geocodingData['status'] == 'OK' &&
                geocodingData['results'].length > 0) {
              // Obtener la ubicación geográfica (latitud y longitud) del lugar
              var location =
                  geocodingData['results'][0]['geometry']['location'];
              double latitude = location['lat'];
              double longitude = location['lng'];

              // Hacer lo que desees con la latitud y longitud obtenidas
              print("Latitud: $latitude");
              print("Longitud: $longitude");
            } else {
              print("No se encontraron resultados de geocoding para el lugar.");
            }
          } else {
            print("Error al obtener datos de geocoding.");
          } */
        } else {
          print(
              "No se encontraron resultados de Place Autocomplete para la consulta.");
        }
      } else {
        print("Error al obtener datos de Place Autocomplete.");
      }
    } else {
      final combinedResults = getCombinedResults(query);
      setState(() {
        datosUbicacion = combinedResults;
      });
    }
  }

  List<Ubicaciones> getCombinedResults(String query) {
    if (query.isEmpty) {
      return [];
    }

    final searchQuery = removeAccents(query.toLowerCase());

    return ubiService.ubicaciones
        .where((ubicacion) =>
            (ubicacion.description != null &&
                removeAccents(ubicacion.description!.toLowerCase())
                    .contains(searchQuery)) ||
            (ubicacion.group != null &&
                removeAccents(ubicacion.group!.toLowerCase())
                    .contains(searchQuery)) ||
            (ubicacion.location != null &&
                removeAccents(ubicacion.location!.toLowerCase())
                    .contains(searchQuery)))
        .toList();
  }

  String removeAccents(String input) {
    final accentsMap = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    return input.replaceAllMapped(
        RegExp(r'[áéíóúüñ]'), (match) => accentsMap[match.group(0)]!);
  }

  getAddressFromLatLng() async {
    try {
      /* print("Entro a getAddressFromLatLng()"); */
      if (isLoading) {
        setState(() {});
      } else {
        GeoData dataGeo = await Geocoder2.getDataFromCoordinates(
            latitude: iniLocation?.latitude ?? -17.783299,
            longitude: iniLocation?.longitude ?? -63.182129,
            googleMapApiKey: apiGoogle);
        setState(() {
          isLoading = false;
          address = dataGeo.address;
          if (kDebugMode) {
            print("Dirección: $address");
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
      setState(() {
        isLoading = true;
      });
    }
  }

  /// This has to happen only once per app

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ubiService = Provider.of<UbiService>(context, listen: true);
  }

  @override
  void initState() {
    _init();
    getCurrentLocation();

    super.initState();
  }

  @override
  void dispose() {
    // Dispose el TextEditingController al finalizar
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ubiService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          if (currentLocation == null)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: LatLng(
                      currentLocation!.latitude!,
                      currentLocation!.longitude!,
                    ),
                    zoom: 14.5),
                onMapCreated: (GoogleMapController controller) {
                  _completer.complete(controller);
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                trafficEnabled: false,
                mapType: MapType.normal,
                compassEnabled: false,
                markers: markers,
                myLocationEnabled: true,
                onCameraMove: (CameraPosition? position) {
                  /* if (kDebugMode) {
                    print("Camera Move");
                  } */ // ! ESTO GENERA PROBLEMAS A LA HORA DE HACER DEBUG - LO PONE LENTO
                  isLoading = false;
                  iniLocation = position!.target;
                  isLoading = true;
                  getAddressFromLatLng();
                },
                onCameraIdle: () {
                  /* if (kDebugMode) {
                    print("Camera Idle");
                  } */ // ! IGUAL ESTO
                  isLoading = false;
                  getAddressFromLatLng();
                },
                polylines: {
                  if (travelMode == TravelMode.driving) ...autoPolylines,
                  if (travelMode == TravelMode.walking) ...walkingPolylines,
                },
              ),
            ),
          if (dosPuntos)
            TrayectoriaInfo(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Centrar los elementos horizontalmente
                children: [
                  //DESCRIPCION
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        //GRUPO
                        Text(
                          group,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      LocationInfo(
                        icon: Icons.directions_car,
                        title: "Auto",
                        description: tiempoAuto,
                        isSelected: travelMode == TravelMode.driving,
                        onPressed: () {
                          setState(() {
                            travelMode = TravelMode.driving;
                          });
                          createPolylines(position);
                        },
                      ),
                      LocationInfo(
                        icon: Icons.directions_walk,
                        title: "Pie",
                        description: tiempoCaminando,
                        isSelected: travelMode == TravelMode.walking,
                        onPressed: () {
                          setState(() {
                            travelMode = TravelMode.walking;
                          });
                          createPolylines(position);
                        },
                      ),
                      LocationInfo(
                        icon: Icons.place,
                        title: "Distancia",
                        description: "$totalDistance km",
                        isSelected: false,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (finMarker == false &&
              mostrarMarcador == true &&
              miUbicacion == false)
            PanelMarcaInicio(
              onPressed: () {
                modalMarcaInicio(context);
              },
            ),
          if (mostrarMarcador == false)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 130,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 25, right: 25, top: 10, bottom: 10),
                  child: Column(
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Aceptar'),
                          onPressed: () {
                            _completer.future
                                .then((GoogleMapController controller) {
                              controller
                                  .getVisibleRegion()
                                  .then((LatLngBounds bounds) {
                                final LatLng centerLatLng = LatLng(
                                  (bounds.northeast.latitude +
                                          bounds.southwest.latitude) /
                                      2,
                                  (bounds.northeast.longitude +
                                          bounds.southwest.longitude) /
                                      2,
                                );
                                inicioLatitude = centerLatLng.latitude;
                                inicioLongitude = centerLatLng.longitude;
                                dosPuntos = false;
                                mostrarMarcador = false;
                                bandera = false;
                                finMarker = true;
                                addMarker(centerLatLng);
                              });
                            });
                          }),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Cancelar'),
                          onPressed: () async {
                            mostrarMarcador = true;
                            if (markers.isNotEmpty) {
                              if (dosPuntos == false) {
                                miUbicacion = false;
                                finMarker = false;
                                dosPuntos = false;
                                removeMarker(markers.first.markerId);
                              } else {
                                removeMarker(markers.first.markerId);
                                removeMarker(markers.last.markerId);
                                mostrarMarcador = true;
                                dosPuntos = false;
                                finMarker = false;
                              }
                            }

                            final GoogleMapController controller =
                                await _mapController;
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    currentLocation!.latitude!,
                                    currentLocation!.longitude!,
                                  ),
                                  zoom: 14.5,
                                ),
                              ),
                            );
                            noGoogle = false;
                            setState(() {});
                          }),
                    ],
                  ),
                ),
              ),
            ),
          /* Cancelar */
          if (miUbicacion)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 25, right: 25, top: 10, bottom: 10),
                  child: Column(
                    children: [
                      /* Cancelar */
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Cancelar'),
                          onPressed: () async {
                            miUbicacion = false;
                            noGoogle = false;

                            if (markers.isNotEmpty) {
                              if (dosPuntos == false) {
                                miUbicacion = false;
                                finMarker = false;
                                dosPuntos = false;
                                removeMarker(markers.first.markerId);
                              } else {
                                removeMarker(markers.first.markerId);
                                removeMarker(markers.last.markerId);
                                mostrarMarcador = true;
                                dosPuntos = false;
                                finMarker = false;
                              }
                            }

                            final GoogleMapController controller =
                                await _mapController;
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    currentLocation!.latitude!,
                                    currentLocation!.longitude!,
                                  ),
                                  zoom: 14.5,
                                ),
                              ),
                            );
                            noGoogle = false;
                            setState(() {});
                          }),
                    ],
                  ),
                ),
              ),
            ),
          if (finMarker == true)
            Positioned(
              top: 150,
              right: 10,
              child: FloatingActionButton(
                heroTag: 'add_location',
                backgroundColor: Colors.red,
                onPressed: () async {
                  _completer.future.then((GoogleMapController controller) {
                    controller.getVisibleRegion().then((LatLngBounds bounds) {
                      if (dosPuntos == false) {
                        miUbicacion = false;
                        finMarker = false;
                        dosPuntos = false;
                        removeMarker(markers.first.markerId);
                      } else {
                        removeMarker(markers.first.markerId);
                        removeMarker(markers.last.markerId);
                        mostrarMarcador = true;
                        dosPuntos = false;
                        finMarker = false;
                      }
                    });
                  });
                  setState(() {
                    noGoogle = false;
                    /*  findGoogle = false; */
                  });
                  final GoogleMapController controller = await _mapController;
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(
                          currentLocation!.latitude!,
                          currentLocation!.longitude!,
                        ),
                        zoom: 14.5,
                      ),
                    ),
                  );
                },
                mini: true,
                child: const Icon(Icons.clear, color: Colors.white),
              ),
            ),
          if (mostrarMarcador == false)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 38),
                child: Opacity(
                  opacity: markers.isEmpty ? 1.0 : 0.0,
                  child: Image.asset(
                    'assets/icons/mark_start.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
            ),
          if (mostrarMarcador == false)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 110),
                child: Container(
                  color: isLoading ? Colors.transparent : Colors.white,
                  child: isLoading
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: SpinKitFadingCircle(
                            color: Colors.green,
                            size: 30,
                          ),
                        )
                      : Text(
                          address,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          Positioned(
            top: 100,
            right: 10,
            child: FloatingActionButton(
              heroTag: 'my_location',
              onPressed: () async {
                GoogleMapController controller = await _mapController;
                ubicacionActual(controller);
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[800],
              mini: true,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            top: 100,
            left: 10,
            child: FloatingActionButton(
              heroTag: 'zoom_in',
              onPressed: () async {
                GoogleMapController controller = await _mapController;
                setState(() {
                  changeZoom(controller, true);
                });
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[800],
              mini: true, // Ajustar tamaño a pequeño
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            top: 150,
            left: 10,
            child: FloatingActionButton(
              heroTag: 'zoom_out',
              onPressed: () async {
                GoogleMapController controller = await _mapController;
                setState(() {
                  changeZoom(controller, false);
                });
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[800],
              mini: true, // Ajustar tamaño a pequeño
              child: const Icon(Icons.remove),
            ),
          ),
          if (mostrarMarcador == true && dosPuntos == false)
            buildFloatingSearchBar(context),
        ],
      ),
    );
  }

  final GlobalKey<FloatingSearchBarState> _searchBarKey =
      GlobalKey<FloatingSearchBarState>();

  Widget buildFloatingSearchBar(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      key: _searchBarKey,
      controller: _searchBarController,
      hint: 'Buscar lugar',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 500),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 400),
      borderRadius: BorderRadius.circular(30),
      onQueryChanged: (query) {
        search(query);
      },
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        /* FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.place),
            onPressed: () {},
          ),
        ), */
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
        FloatingSearchBarAction(
          showIfClosed: true,
          showIfOpened: true,
          child: isListening
              ? CircularButton(
                  icon: const Icon(Icons.stop),
                  onPressed: stopListening,
                )
              : CircularButton(
                  icon: const Icon(Icons.mic),
                  onPressed: startListening,
                ),
        ),
      ],
      builder: (context, transition) {
        return miUbicacion == true && noGoogle == false
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Material(
                  color: Colors.white,
                  elevation: 4.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: placePredictionList.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final item = placePredictionList[index];
                      return ListTile(
                        title: Text((item.description).toString()),
                        subtitle: Text(item.structuredFormatting!.secondaryText
                            .toString()),
                        iconColor: Colors.blue,
                        dense: true,
                        leading: const Icon(Icons.location_on),
                        onTap: () async {
                          String placeId = item.placeId!;

                          // Utilizar el ID del lugar para obtener detalles de geocoding
                          Uri geocodingUri = Uri.https(
                              "maps.googleapis.com", "/maps/api/geocode/json", {
                            "place_id": placeId,
                            "key": apiGoogle,
                          });

                          // Realizar la solicitud a la API de Geocoding
                          var geocodingResponse = await http.get(geocodingUri);
                          if (geocodingResponse.statusCode == 200) {
                            // Decodificar la respuesta JSON de Geocoding
                            var geocodingData =
                                json.decode(geocodingResponse.body);

                            // Verificar si hay resultados
                            if (geocodingData['status'] == 'OK' &&
                                geocodingData['results'].length > 0) {
                              // Obtener la ubicación geográfica (latitud y longitud) del lugar
                              var location = geocodingData['results'][0]
                                  ['geometry']['location'];
                              double latitude = location['lat'];
                              double longitude = location['lng'];

                              // Hacer lo que desees con la latitud y longitud obtenidas
                              print("Latitud: $latitude");
                              print("Longitud: $longitude");

                              inicioLatitude = latitude;
                              inicioLongitude = longitude;
                              mostrarMarcador = true;
                              miUbicacion = false;
                              bandera = false;
                              addMarker(LatLng(latitude, longitude));

                              final GoogleMapController controller =
                                  await _mapController;
                              controller.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      inicioLatitude,
                                      inicioLongitude,
                                    ),
                                    zoom: 14.5,
                                  ),
                                ),
                              );

                              finMarker = true;
                              noGoogle = true;
                              /* findGoogle = true; */
                              setState(() {
                                search('');
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              });
                              _searchBarKey.currentState?.close();
                            } else {
                              print(
                                  "No se encontraron resultados de geocoding para el lugar.");
                            }
                          } else {
                            print("Error al obtener datos de geocoding.");
                          }
                        },
                      );
                    },
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Material(
                  color: Colors.white,
                  elevation: 4.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: datosUbicacion.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final item = datosUbicacion[index];
                      /* final groupValue = getGroupForItem(item!); */

                      return ListTile(
                        title: Text(item!.description!),
                        subtitle: Text('${item.group} - ${item.location}'),
                        iconColor: Colors.blue,
                        dense: true,
                        leading: const Icon(Icons.location_on),
                        onTap: () {
                          if (markers.isNotEmpty) {
                            position = LatLng(
                              double.parse(item.latitude!),
                              double.parse(item.longitude!),
                            );

                            dosPuntos = true;
                            miUbicacion = false;
                            description = item.description!;
                            group = item.group!;
                            initials = item.initials!;

                            addMarker(position);

                            setState(() {
                              search('');
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            });
                            _searchBarKey.currentState?.close();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('No se ha definido el punto inicial'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              );
      },
    );
  }

  Future<dynamic> modalMarcaInicio(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            height: 200,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  /* Buscar Por Google */
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          miUbicacion = true;
                        });
                        _searchBarController.open();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Buscar por Google'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        mostrarMarcador = false;
                        noGoogle = true;
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Marcar en el mapa'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        onPressed: () async {
                          inicioLatitude = currentLocation!.latitude!;
                          inicioLongitude = currentLocation!
                              .longitude!; //currentLocation!.longitude!;
                          mostrarMarcador = true;
                          miUbicacion = true;
                          noGoogle = true;
                          bandera = false;
                          addMarker(LatLng(
                            currentLocation!.latitude!,
                            currentLocation!.longitude!,
                          ));
                          final GoogleMapController controller =
                              await _mapController;

                          controller.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  inicioLatitude,
                                  inicioLongitude,
                                ),
                                zoom: 14.5,
                              ),
                            ),
                          );
                          finMarker = true;
                          setState(() {});
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Desde mi ubicación")),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
