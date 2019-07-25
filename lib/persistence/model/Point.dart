import 'dart:convert';

Point routeFromJson(String str) {
  final jsonData = json.decode(str);
  return Point.fromMap(jsonData);
}

String clientToJson(Point data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Point {
  String name;
  double latitude;
  double longitude;

  Point({
    this.name,
    this.latitude,
    this.longitude,
  });

  factory Point.fromMap(Map<String, dynamic> json) => new Point(
    name: json["name"],
    latitude: json["latitude"],
    longitude: json["longitude"],
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "latitude": latitude,
    "longitude": longitude,
  };

  @override
  String toString() {
    return 'Point{name: $name, latitude: $latitude, longitude: $longitude,}';
  }

}
