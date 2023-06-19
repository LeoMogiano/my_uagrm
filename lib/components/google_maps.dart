import 'dart:math';


import 'package:location/location.dart';
import 'package:image/image.dart' as img;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ComponentsGoogleMaps {
  Future<void> addMarker(
    LatLng position,
    bool bandera,
    bool miUbicacion,
    bool dosPuntos,
    bool mostrarMarcador,
    Set<Marker> markers,
    LocationData currentLocation,
    Future<GoogleMapController> mapController,
    List<LatLng> polylineCoordinates,
    double inicioLatitude,
    double inicioLongitude,
    double totalDistance,
  ) async {
    if (bandera) {
      removeMarker(
          markers.last.markerId, markers, polylineCoordinates, mostrarMarcador);
      bandera = false;
    }

    if (miUbicacion) {
      final GoogleMapController controller = await mapController;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!,
            ),
            zoom: 14.5,
          ),
        ),
      );
    }

    if (!dosPuntos) {
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
      mostrarMarcador = false;
      markers.add(newMarker);
      if (dosPuntos) {
        await createPolylines(
            position,
            inicioLatitude,
            inicioLongitude,
            polylineCoordinates,
            bandera,
            miUbicacion,
            currentLocation,
            mapController,
            totalDistance);
      }
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
      mostrarMarcador = false;
      markers.add(newMarker);
      if (dosPuntos) {
        await createPolylines(
            position,
            inicioLatitude,
            inicioLongitude,
            polylineCoordinates,
            bandera,
            miUbicacion,
            currentLocation,
            mapController,
            totalDistance);
      }
    }
  }

  final String apiGoogle = dotenv.env['API_GOOGLE'] ?? '';

  void removeMarker(MarkerId markerId, Set<Marker> markers,
      List<LatLng> polylineCoordinates, bool mostrarMarcador) {
    markers.removeWhere((marker) => marker.markerId == markerId);
    polylineCoordinates.clear();
    mostrarMarcador = true;
  }

  Future<void> createPolylines(
    LatLng position,
    double inicioLatitude,
    double inicioLongitude,
    List<LatLng> polylineCoordinates,
    bool bandera,
    bool miUbicacion,
    LocationData currentLocation,
    Future<GoogleMapController> mapController,
    double totalDistance,
  ) async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiGoogle,
      PointLatLng(inicioLatitude, inicioLongitude),
      PointLatLng(position.latitude, position.longitude),
    );

    if (result.status == 'OK') {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      calculatePolylineDistance(polylineCoordinates, totalDistance);
    }

    bandera = true;

    if (miUbicacion) {
      final GoogleMapController controller = await mapController;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!,
            ),
            zoom: 14.5,
          ),
        ),
      );
    }
  }

  void calculatePolylineDistance(
      List<LatLng> polylineCoordinates, double totalDistance) {
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
}
