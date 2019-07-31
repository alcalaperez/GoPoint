import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gopoint/persistence/model/MapsDTO.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
const apiKey = "APIKEY";

class GoogleMapsServices{
  Future<MapsDTO> getRouteCoordinates(LatLng l1, LatLng l2, String mode)async{
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=$apiKey&mode=$mode";
    http.Response response = await http.get(url);
    Map values = jsonDecode(response.body);
    MapsDTO dto = new MapsDTO(values["routes"][0]["overview_polyline"]["points"], values["routes"][0]["legs"][0]["distance"]["text"], values["routes"][0]["legs"][0]["duration"]["text"],
        values["routes"][0]["legs"][0]["start_address"], values["routes"][0]["legs"][0]["end_address"]);
    return dto;
  }
}