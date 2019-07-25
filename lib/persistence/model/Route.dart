import 'dart:convert';

Routes routeFromJson(String str) {
  final jsonData = json.decode(str);
  return Routes.fromMap(jsonData);
}

String clientToJson(Routes data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Routes {
  String name;
  double originLatitude;
  double originLongitude;
  double destinyLatitude;
  double destinyLongitude;

  Routes({
    this.name,
    this.originLatitude,
    this.originLongitude,
    this.destinyLatitude,
    this.destinyLongitude,

  });

  factory Routes.fromMap(Map<String, dynamic> json) => new Routes(
    name: json["name"],
    originLatitude: json["originLatitude"],
    originLongitude: json["originLongitude"],
    destinyLatitude: json["destinyLatitude"],
    destinyLongitude: json["destinyLongitude"],

  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "originLatitude": originLatitude,
    "originLongitude": originLongitude,
    "destinyLatitude": destinyLatitude,
    "destinyLongitude": destinyLongitude,
  };

  @override
  String toString() {
    return 'Route{name: $name, originLatitude: $originLatitude, originLongitude: $originLongitude, destinyLatitude: $destinyLatitude, destinyLongitude: $destinyLongitude}';
  }

}
