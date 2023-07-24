import 'dart:async';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:location/location.dart';

Future<void> ubicacionActual(GoogleMapController? mapController) async {
  Location location = Location();
  LocationData? locationData = await location.getLocation();
  if (mapController != null) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            locationData.latitude!,
            locationData.longitude!,
          ),
          zoom: 14.5,
        ),
      ),
    );
  }
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

Map<String, String> calculateTime(double totalDistance) {
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

  return {
    'tiempoAuto': carTimeFormatted,
    'tiempoCaminando': walkingTimeFormatted,
  };
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

double calculatePolylineDistance(List<LatLng> polylineCoordinates) {
  double totalDistance = 0.0;

  for (int i = 0; i < polylineCoordinates.length - 1; i++) {
    final LatLng start = polylineCoordinates[i];
    final LatLng end = polylineCoordinates[i + 1];

    final double segmentDistance = calculateDistance(start, end);
    totalDistance += segmentDistance;
  }

  totalDistance = double.parse(totalDistance.toStringAsFixed(2));

  return totalDistance;
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

void changeZoom(GoogleMapController controller, bool zoomIn) async {
  double zoom = await controller.getZoomLevel();
  Location location = Location();
  LocationData? locationData = await location.getLocation();

  zoom = zoomIn ? zoom + 1 : zoom - 1;

  controller.animateCamera(CameraUpdate.newCameraPosition(
    CameraPosition(
      target: LatLng(
        locationData.latitude!,
        locationData.longitude!,
      ),
      zoom: zoom,
    ),
  ));
}
