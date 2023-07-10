import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sig_grupL/widgets/widgets.dart';

import '../controllers/api_controller.dart';
import 'package:sig_grupL/utils/utils.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
  List<String> datosDescription = [];
  List<String> datosGroup = [];

  final TextEditingController _searchController = TextEditingController();

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
        calculatePolylineDistance(polylineCoordinates);
        calculateTime();
        calculatePolylineDistance(polylineCoordinates);

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

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;

    for (final latLng in list) {
      if (minLat == null || latLng.latitude < minLat) {
        minLat = latLng.latitude;
      }
      if (maxLat == null || latLng.latitude > maxLat) {
        maxLat = latLng.latitude;
      }
      if (minLng == null || latLng.longitude < minLng) {
        minLng = latLng.longitude;
      }
      if (maxLng == null || latLng.longitude > maxLng) {
        maxLng = latLng.longitude;
      }
    }

    return LatLngBounds(
      northeast: LatLng(maxLat!, maxLng!),
      southwest: LatLng(minLat!, minLng!),
    );
  }

  void calculatePolylineDistance(List<LatLng> polylineCoordinates) {
    totalDistance = 0.0;

    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      final LatLng start = polylineCoordinates[i];
      final LatLng end = polylineCoordinates[i + 1];

      final double segmentDistance = calculateDistance(start, end);
      totalDistance += segmentDistance;
    }

    totalDistance = double.parse(totalDistance.toStringAsFixed(2));

    if (kDebugMode) {
      print('Distancia total de la polilínea: $totalDistance km');
    }
  }

  double calculateDistance(LatLng start, LatLng end) {
    const int earthRadius = 6371; // Radio de la Tierra en kilómetros

    final double lat1 = start.latitude * pi / 180;
    final double lon1 = start.longitude * pi / 180;
    final double lat2 = end.latitude * pi / 180;
    final double lon2 = end.longitude * pi / 180;

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final double distance = earthRadius * c;
    return distance;
  }

  String formatTime(double time) {
    int hours = (time / 60).floor();
    int minutes = (time % 60).round();

    String formattedTime;

    if (hours > 0) {
      formattedTime = '$hours hr $minutes min';
    } else {
      formattedTime = '$minutes min';
    }

    return formattedTime;
  }

  void calculateTime() {
    // Velocidad promedio a pie en km/h
    const double walkingSpeed = 5.0;

    // Velocidad promedio en automóvil en km/h
    const double carSpeed = 60.0;

    // Calcula el tiempo estimado en minutos
    double walkingTime = (totalDistance / walkingSpeed) * 60;
    double carTime = (totalDistance / carSpeed) * 60;

    // Convierte el tiempo a formato horas:minutos
    String walkingTimeFormatted = formatTime(walkingTime);
    String carTimeFormatted = formatTime(carTime);

    if (kDebugMode) {
      print('Tiempo estimado a pie: $walkingTimeFormatted');
      print('Tiempo estimado en automóvil: $carTimeFormatted');
    }

    tiempoAuto = carTimeFormatted;
    tiempoCaminando = walkingTimeFormatted;
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

  void search(String query) {
    final matchQuery = getMatchedResults(query);
    final matchQueryGroup = getMatchedResultsGroup(query);
    setState(() {
      datosDescription = matchQuery;
      datosGroup = matchQueryGroup;
      if (kDebugMode) {
        print(datosDescription);
      }
      if (kDebugMode) {
        print(datosGroup);
      }
    });
  }

  List<String> getMatchedResults(String query) {
    if (query.isEmpty) {
      return [];
    }

    return jsonData
        .map((item) => item['description'] as String)
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> getMatchedResultsGroup(String query) {
    if (query.isEmpty) {
      return [];
    }

    List<String> group = [];
    for (var i = 0; i < jsonData.length; i++) {
      String description = jsonData[i]['description'] as String;
      if (description.toLowerCase().contains(query.toLowerCase())) {
        group.add(jsonData[i]['group'] as String);
      }
    }
    return group;
  }

  getAddressFromLatLng() async {
    try {
      /* print("Entro a getAddressFromLatLng()"); */
      if (isLoading) {
        setState(() {});
      } else {
        GeoData dataGeo = await Geocoder2.getDataFromCoordinates(
            latitude: iniLocation!.latitude,
            longitude: iniLocation!.longitude,
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

  @override
  void initState() {
    _init();
    getCurrentLocation();
    ApiController().leerJSON().then((data) {
      setState(() {
        jsonData = data;
        datosDescription =
            jsonData.map((item) => item['description'] as String).toList();
        datosGroup = jsonData.map((item) => item['group'] as String).toList();
      });
    }).catchError((error) {
      // Manejar el error de lectura del JSON
      if (kDebugMode) {
        print("Error: $error");
      }
    });
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
          if (finMarker == false && mostrarMarcador == true)
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
                          onPressed: () {
                            mostrarMarcador = true;
                            setState(() {});
                          }),
                    ],
                  ),
                ),
              ),
            ),
          if (finMarker == true)
            Container(
              margin: const EdgeInsets.only(top: 100, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'add_location',
                    backgroundColor: Colors.red,
                    onPressed: () {
                      _completer.future.then((GoogleMapController controller) {
                        controller
                            .getVisibleRegion()
                            .then((LatLngBounds bounds) {
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
                    },
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                ],
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
        // Call your model, bloc, controller here.
        search(query);
      },
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.place),
            onPressed: () {},
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: ListView.builder(
              shrinkWrap: true, // Ajusta el tamaño al contenido
              itemCount: datosDescription.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final itemDescrip = datosDescription[index];
                final itemGroup = datosGroup[index];

                return ListTile(
                  title: Text(itemDescrip),
                  subtitle: Text(itemGroup), // Aquí puedes poner el grupo
                  iconColor: Colors.blue,
                  dense: true,
                  /* icon ojo */
                  leading: const Icon(
                    Icons.location_on,
                  ),
                  onTap: () {
                    if (markers.isNotEmpty) {
                      final data = jsonData.firstWhere(
                        (element) => element['description'] == itemDescrip,
                        orElse: () => {
                          'description': '',
                          'latitude': '0',
                          'longitude': '0',
                        },
                      );
                      position = LatLng(
                        double.parse(data['latitude'].toString()),
                        double.parse(data['longitude'].toString()),
                      );

                      // Aquí puedes hacer lo que necesites con las coordenadas
                      dosPuntos = true;
                      miUbicacion = false;
                      description = data['description'].toString();
                      group = data['group'].toString();
                      initials = data['initials'].toString();
                      // Por ejemplo, agregar un marcador
                      addMarker(position);
                      // Cerrar el buscador y volver a la pantalla principal
                      setState(() {
                        search('');
                        _searchController.clear();
                        /* Ocultar teclado */
                        FocusScope.of(context).unfocus();
                      });
                      _searchBarKey.currentState?.close();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se ha definido el punto inicial'),
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
            height: 140,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        mostrarMarcador = false;
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
                        onPressed: () {
                          inicioLatitude = currentLocation!.latitude!;
                          inicioLongitude = currentLocation!
                              .longitude!; //currentLocation!.longitude!;
                          mostrarMarcador = true;
                          miUbicacion = true;
                          bandera = false;
                          addMarker(LatLng(
                            currentLocation!.latitude!,
                            currentLocation!.longitude!,
                          ));
                          finMarker = true;
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
                        child: const Text("Desde mi ubicación")),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
