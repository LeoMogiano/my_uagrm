import 'dart:convert';

class Ubicaciones {
  final String? id;
  final String? description;
  final String? buildingCode;
  final String? latitude;
  final String? longitude;
  final String? group;
  final String? initials;

  Ubicaciones({
     this.id,
    this.description,
    this.buildingCode,
    this.latitude,
    this.longitude,
    this.group,
    this.initials,
  });

  factory Ubicaciones.fromJson(String str) =>
      Ubicaciones.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Ubicaciones.fromMap(Map<String, dynamic> json) => Ubicaciones(
        id: json["_id"],
        description: json["description"],
        buildingCode: json["buildingCode"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        group: json["group"],
        initials: json["initials"],
      );

  Map<String, dynamic> toMap() => {
        "_id": id,
        "description": description,
        "buildingCode": buildingCode,
        "latitude": latitude,
        "longitude": longitude,
        "group": group,
        "initials": initials,
      };

  static List<Ubicaciones> parseUbicaciones(String jsonString) {
    final parsedJson = json.decode(jsonString);
    if (parsedJson is List) {
      return parsedJson
          .map((ubicacion) => Ubicaciones.fromMap(ubicacion))
          .toList();
    } else if (parsedJson is Map) {
      return parsedJson.values
          .map((ubicacion) => Ubicaciones.fromMap(ubicacion))
          .toList();
    }
    return [];
  }
}
