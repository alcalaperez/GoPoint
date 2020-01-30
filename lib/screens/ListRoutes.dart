import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gopoint/persistence/RoutesDatabaseHelper.dart';
import 'package:gopoint/persistence/model/Route.dart';

// MyApp is a StatefulWidget. This allows updating the state of the
// widget when an item is removed.
class RoutesList extends StatefulWidget {
  RoutesList({Key key, this.origin, this.destiny}) : super(key: key);
  final LatLng origin;
  LatLng destiny = null;

  @override
  RoutesListState createState() {
    return RoutesListState();
  }
}

class RoutesListState extends State<RoutesList> {
  TextEditingController _textFieldController = TextEditingController();

  _displayDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: PlatformText('Add a new route'),
        content: new Row(
          children: <Widget>[
            new Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new PlatformTextField(
                      autofocus: true,
                      controller: _textFieldController,
                      android: (_) => MaterialTextFieldData(decoration: InputDecoration(
                          labelText: 'Route Name', hintText: 'eg. My route'),
                      ),
                    )
                  ],
                ))
          ],
        ),
        actions: <Widget>[
          PlatformDialogAction(
            child: PlatformText('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          PlatformDialogAction(
              child: PlatformText('Save'),
              onPressed: () {
                Routes routeToInsert = new Routes(
                    name: _textFieldController.text,
                    originLatitude: widget.origin.latitude,
                    originLongitude: widget.origin.longitude,
                    destinyLatitude: widget.destiny.latitude,
                    destinyLongitude: widget.destiny.longitude);
                DBProviderRoutes().newRoute(routeToInsert);
                _textFieldController.text = "";
                Navigator.of(context).pop();
                setState(() {});
              }),
        ],
      ),
    );
  }

  Future<bool> confirmDismiss(BuildContext context, String action) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PlatformAlertDialog(
          title: PlatformText('Do you want to delete this route?'),
          actions: <Widget>[
            PlatformDialogAction(
              child: PlatformText('Yes'),
              onPressed: () {
                Navigator.pop(context, true); // showDialog() returns true
              },
            ),
            PlatformDialogAction(
              child: PlatformText('No'),
              onPressed: () {
                Navigator.pop(context, false); // showDialog() returns false
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final title = 'Routes';
    return  Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(title),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () => Navigator.pop(context, ""),
          ),
          actions: widget.destiny != null ?
              <Widget>[
                 new IconButton(
                    icon: new Icon(Icons.add_circle),
                   color: Colors.white,
                   onPressed: () {
                      _displayDialog(context);
                    },
                  )
                ,
          ] : <Widget>[Container()],
        ),
        body: FutureBuilder<dynamic>(
          future: DBProviderRoutes().getAllRoutes(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return ListView.separated(
                separatorBuilder: (context, index) => Divider(
                    height: 0.0
                    ),
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  Routes item = snapshot.data[index];
                  return Dismissible(
                      key: Key(item.name),
                      background: Container(
                        color: Colors.red,
                        child: Icon(Icons.delete, color: Colors.white),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                      ),
                      confirmDismiss: (DismissDirection dismissDirection) {
                        confirmDismiss(context, 'archive').then((bool value) {
                          if (value) {
                            DBProviderRoutes().deleteRoute(item.name);
                            setState(() {});
                          }
                        });
                      },
                      direction: DismissDirection.endToStart,
                      child: ListTile(
                          title: Text(item.name),
                          onTap: () {
                            Navigator.pop(context, item.name);
                            },
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.keyboard_arrow_left,
                                color: Colors.red,
                              ),
                              Text(
                                "Swipe to delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          )));
                },
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
    );
  }
}
