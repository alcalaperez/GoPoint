import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gopoint/persistence/RoutesDatabaseHelper.dart';
import 'package:gopoint/persistence/PointsDatabaseHelper.dart';
import 'package:gopoint/persistence/model/MapsDTO.dart';
import 'package:gopoint/persistence/model/Point.dart';
import 'package:gopoint/persistence/model/Route.dart';
import 'package:gopoint/screens/ListRoutes.dart';
import '../requests/google_maps_requests.dart';
import 'ListPoints.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gopoint/util/popup_menu.dart';

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
  final textEditingDestinationController = TextEditingController();
  static LatLng _initialPosition;
  LatLng _lastPosition = _initialPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  final icons = [
    Icons.directions_car,
    Icons.directions_walk,
    Icons.directions_bike
  ];

  String mapsTransitMode = "driving";
  IconData modeSelected = Icons.directions_car;
  String duration = "";
  String startAddress = "Please select a point in the map (long press).";
  String endAddress = "Press the middle button to change transport.";

  //walking
  //bicycling
  //transit

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    PopupMenu.context = context;
    GlobalKey btnKey = GlobalKey();

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
                  myLocationButtonEnabled: true,
                  zoomGesturesEnabled: true,
                  markers: _markers,
                  onCameraMove: _onCameraMove,
                  polylines: _polyLines,
                ),
                Positioned(
                    top: 55.0,
                    right: 25.0,
                    left: 25.0,
                    child: Container(
                        height: 80.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3.0),
                          color: Colors.orange,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey,
                                offset: Offset(1.0, 5.0),
                                blurRadius: 10,
                                spreadRadius: 3)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            new Text(
                              startAddress,
                              style: TextStyle(color: Colors.white),
                            ),
                            new Text(
                              endAddress,
                              style: TextStyle(color: Colors.white),
                            ),
                            new Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(duration,
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ))),
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
                            Text(
                              "Routes",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        onTap: () async {
                          String nameRoute = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RoutesList(
                                      origin: _initialPosition,
                                      destiny: _markers.length > 1
                                          ? LatLng(
                                              _markers.last.position.latitude,
                                              _markers.last.position.longitude)
                                          : null)));

                          if (nameRoute != "") {
                            Routes route =
                                await DBProviderRoutes().getRoute(nameRoute);
                            _polyLines.clear();
                            _initialPosition = new LatLng(
                                route.originLatitude, route.originLongitude);
                            sendRequestSavedRoute(
                                new LatLng(route.originLatitude,
                                    route.originLongitude),
                                new LatLng(route.destinyLatitude,
                                    route.destinyLongitude));
                          }
                        },
                      )),
                  Padding(
                      padding:
                          const EdgeInsets.only(right: 30, bottom: 5, top: 2),
                      child: GestureDetector(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.pin_drop,
                              size: 30.0,
                              color: Colors.white,
                            ),
                            Text(
                              "Map points",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        onTap: () async {
                          String namePoint = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PointsList(
                                      pointToSave: _initialPosition)));
                          if (namePoint != "") {
                            Point point =
                                await DBProviderPoints().getPoint(namePoint);
                            _polyLines.clear();
                            _getUserLocation();
                            _markers.clear();
                            sendRequestSavedRoute(_initialPosition,
                                new LatLng(point.latitude, point.longitude));
                          }
                        },
                      ))
                ],
              ),
            ),
            floatingActionButton: new FloatingActionButton(
              child: Icon(
                modeSelected,
                color: Colors.white,
                key: btnKey,
              ),
              onPressed: () {
                PopupMenu menu = PopupMenu(
                    backgroundColor: Colors.black54,
                    items: [
                      MenuItem(
                          title: 'Car',
                          image: Icon(
                            Icons.directions_car,
                            color: Colors.white,
                          )),
                      MenuItem(
                          title: 'Bike',
                          image: Icon(
                            Icons.directions_bike,
                            color: Colors.white,
                          )),
                      MenuItem(
                          title: 'Walking',
                          image: Icon(
                            Icons.directions_run,
                            color: Colors.white,
                          )),
                      MenuItem(
                          title: 'Public transport',
                          image: Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                          ))
                    ],
                    onClickMenu: onClickMenu,
                    onDismiss: onDismiss);

                menu.show(widgetKey: btnKey);
              },
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
  }

  callRoutesScreen(BuildContext context) async {
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RoutesList(
                origin: _initialPosition,
                destiny: _markers.length > 1
                    ? LatLng(_markers.last.position.latitude,
                        _markers.last.position.longitude)
                    : null)));

    if (result != null) {
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

  void createRoute(String encondedPoly, String duration, String distance,
      String startAddress, String endAddress) {
    setState(() {
      this.startAddress =
          startAddress.split(",")[0] + "," + startAddress.split(",")[1];
      this.endAddress =
          endAddress.split(",")[0] + "," + endAddress.split(",")[1];
      this.duration = "Duration: " + duration + "     Distance: " + distance;
      _polyLines.clear();
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
    bool permitted = await requestLocationPermission();
    if (!permitted) {
      Scaffold.of(context).showSnackBar(new SnackBar(
        content:
            new Text("You need to give location permission to use this app"),
      ));
    }
    Position position = await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await placemarkFromCoordinates(position.latitude, position.longitude);
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
    MapsDTO mapsDTO = await _googleMapsServices.getRouteCoordinates(
        _initialPosition, destination, mapsTransitMode);
    createRoute(mapsDTO.polylines, mapsDTO.time, mapsDTO.distance,
        mapsDTO.startAddress, mapsDTO.endAddress);
  }

  void sendRequestSavedRoute(LatLng origin, LatLng destiny) async {
    _markers.clear();
    addMarker(origin, "Origin");
    addMarker(destiny, "Destiny");
    MapsDTO mapsDTO = await _googleMapsServices.getRouteCoordinates(
        origin, destiny, mapsTransitMode);
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: origin, zoom: 14.0),
      ),
    );
    createRoute(mapsDTO.polylines, mapsDTO.time, mapsDTO.distance,
        mapsDTO.startAddress, mapsDTO.endAddress);
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

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.request().isGranted) {
      return true;
    }
    return false;
  }

  Future<bool> requestLocationPermission() async {
    return _requestPermission(Permission.locationWhenInUse);
  }

  Future<bool> hasPermission(Permission permission) async {
    return permission.isGranted;
  }

  void onClickMenu(MenuItemProvider item) {
    print('Click menu -> ${item.menuTitle}');
    if (item.menuTitle == "Bike") {
      modeSelected = Icons.directions_bike;
      mapsTransitMode = "bicycling";
    } else if (item.menuTitle == "Car") {
      modeSelected = Icons.directions_car;
      mapsTransitMode = "driving";
    } else if (item.menuTitle == "Walking") {
      modeSelected = Icons.directions_run;
      mapsTransitMode = "walking";
    } else if (item.menuTitle == "Public transport") {
      modeSelected = Icons.directions_bus;
      mapsTransitMode = "transit";
    }

    setState(() {});

    if(_markers.length > 0) {
      sendRequest();
    }
    //walking
    //bicycling
    //transit
  }

  void onDismiss() {
    print('Menu is closed');
  }
}
