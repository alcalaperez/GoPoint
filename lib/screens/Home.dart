import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gopoint/persistence/RoutesDatabaseHelper.dart';
import 'package:gopoint/persistence/PointsDatabaseHelper.dart';
import 'package:gopoint/persistence/model/Point.dart';
import 'package:gopoint/persistence/model/Route.dart';
import 'package:gopoint/screens/ListRoutes.dart';
import '../requests/google_maps_requests.dart';
import 'ListPoints.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Map());
  }
}

class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> with TickerProviderStateMixin {
  GoogleMapController mapController;
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  TextEditingController locationController = TextEditingController();
  final TextEditingestinationController = TextEditingController();
  static LatLng _initialPosition;
  LatLng _lastPosition = _initialPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  final icons = [
    Icons.directions_car,
    Icons.directions_walk,
    Icons.directions_bike
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return _initialPosition == null
        ? Container(
            alignment: Alignment.center,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _initialPosition, zoom: 16.0),
                  onMapCreated: onCreated,
                  onLongPress: _onLongPress,
                  myLocationEnabled: true,
                  mapType: MapType.normal,
                  compassEnabled: true,
                  markers: _markers,
                  onCameraMove: _onCameraMove,
                  polylines: _polyLines,
                ),
              ],
            ),
            bottomNavigationBar: new BottomAppBar(
              shape: CircularNotchedRectangle(),
              color: Colors.orange,
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.only(left: 30, bottom: 5),
                      child: GestureDetector(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.timeline,
                              size: 30.0,
                              color: Colors.white,
                            ),
                            Text("Routes", style: TextStyle(color: Colors.white),),
                          ],
                        ),
                        onTap: () async {
                          String nameRoute = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RoutesList(origin: _initialPosition,
                                  destiny: _markers.length > 1
                                      ? LatLng(
                                      _markers.last.position.latitude,
                                      _markers.last.position.longitude)
                                      : null)));

                          if(nameRoute != "") {
                            Routes route = await DBProviderRoutes().getRoute(nameRoute);
                            _polyLines.clear();
                            _initialPosition = new LatLng(route.originLatitude, route.originLongitude);
                            sendRequestSavedRoute(new LatLng(route.originLatitude, route.originLongitude), new LatLng(route.destinyLatitude, route.destinyLongitude));
                          }
                        },
                      )),
                  Padding(
                      padding: const EdgeInsets.only(right: 30, bottom: 5, top: 2),
                      child: GestureDetector(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.pin_drop,
                              size: 30.0,
                              color: Colors.white,
                            ),
                            Text("Map points", style: TextStyle(color: Colors.white),),
                          ],
                        ),
                        onTap: () async{
                          String namePoint = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PointsList(pointToSave: _initialPosition)));
                          if(namePoint != "") {
                            Point point = await DBProviderPoints().getPoint(namePoint);
                            _polyLines.clear();
                            _getUserLocation();
                            _markers.clear();
                            sendRequestSavedRoute(_initialPosition, new LatLng(point.latitude, point.longitude));
                          }
                        },
                      ))
                ],
              ),
            ),
            floatingActionButton: new FloatingActionButton(
              child: Icon(Icons.settings, color:  Colors.white,),
              onPressed: () {},
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
  }

  callRoutesScreen(BuildContext context) async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RoutesList(origin: _initialPosition,
          destiny: _markers.length > 1
              ? LatLng(
              _markers.last.position.latitude,
              _markers.last.position.longitude)
              : null)));

    if(result != null) {
      print(result.toString());
    }

  }

  void onCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onLongPress(LatLng point) {
    _polyLines.clear();
    if (_markers.length >= 2) {
      _markers.remove(_markers.last);
    }
    setState(() {
      addMarker(point, "Destiny");
    });
    sendRequest();
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _lastPosition = position.target;
    });
  }

  void createRoute(String encondedPoly) {
    setState(() {
      _polyLines.add(Polyline(
          polylineId: PolylineId(_lastPosition.toString()),
          width: 6,
          points: convertToLatLng(decodePoly(encondedPoly)),
          color: Colors.orangeAccent));
    });
  }

/*
* [12.12, 312.2, 321.3, 231.4, 234.5, 2342.6, 2341.7, 1321.4]
* (0-------1-------2------3------4------5-------6-------7)
* */

//  this method will convert list of doubles into latlng
  List<LatLng> convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
// repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negetive then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

/*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    print(lList.toString());

    return lList;
  }

  void _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      locationController.text = placemark[0].name;
      addMarker(_initialPosition, "Origin");
    });
  }

  void sendRequest() async {
    double latitude = _markers.last.position.latitude;
    double longitude = _markers.last.position.longitude;
    LatLng destination = LatLng(latitude, longitude);
    String route = await _googleMapsServices.getRouteCoordinates(
        _initialPosition, destination);
    createRoute(route);
  }

  void sendRequestSavedRoute(LatLng origin, LatLng destiny) async {
    _markers.clear();
    addMarker(origin, "Origin");
    addMarker(destiny, "Destiny");
    String route = await _googleMapsServices.getRouteCoordinates(
        origin, destiny);
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: origin, zoom: 14.0),
      ),
    );
    createRoute(route);

  }

  void addMarker(LatLng point, String title) {
    _markers.add(Marker(
      markerId: MarkerId(point.toString()),
      position: point,
      infoWindow: InfoWindow(
        title: title,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ));
  }
}
