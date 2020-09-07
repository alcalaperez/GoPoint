import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gopoint/persistence/PointsDatabaseHelper.dart';
import 'package:gopoint/persistence/model/Point.dart';

// MyApp is a StatefulWidget. This allows updating the state of the
// widget when an item is removed.
class PointsList extends StatefulWidget {
  PointsList({Key key, this.pointToSave}) : super(key: key);
  LatLng pointToSave;

  @override
  PointsListState createState() {
    return PointsListState();
  }
}

class PointsListState extends State<PointsList> {
  TextEditingController _textFieldController = TextEditingController();

  _displayDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: PlatformText('Add a new point'),
        content: new Row(
          children: <Widget>[
            new Expanded(
                child: Column(
                mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new PlatformTextField(
                  autofocus: true,
                  controller: _textFieldController,
                  material: (context, platform) => MaterialTextFieldData(decoration: InputDecoration(
                      labelText: 'Point Name', hintText: 'eg. My house'),
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
                Point point = new Point(
                    name: _textFieldController.text,
                    latitude: widget.pointToSave.latitude,
                    longitude: widget.pointToSave.longitude);
                DBProviderPoints().newPoint(point);
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
          title: PlatformText('Do you want to delete this point?'),
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
    final title = 'Points';
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context, "");
          },
        ),
        actions: widget.pointToSave != null
            ? <Widget>[
                new IconButton(
                  icon: new Icon(Icons.add_location),
                  color: Colors.white,
                  onPressed: () {
                    _displayDialog(context);
                  },
                ),
              ]
            : <Widget>[Container()],
      ),
      body: FutureBuilder<dynamic>(
        future: DBProviderPoints().getAllPoints(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return ListView.separated(
              separatorBuilder: (context, index) => Divider(
                  height: 0.0
              ),
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                Point item = snapshot.data[index];
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
                          DBProviderPoints().deletePoint(item.name);
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
