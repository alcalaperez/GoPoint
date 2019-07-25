import 'package:gopoint/persistence/model/Point.dart';
import 'Database.dart';

class DBProviderPoints {
  static final DatabaseProvider dbp = DatabaseProvider();

  newPoint(Point point) async {
    final db = await dbp.database;
    var res = await db.insert("Points", point.toMap());
    return res;
  }

  deletePoint(String name) async {
    final db = await dbp.database;
    var res = await db.delete("points", where: "name = ?", whereArgs: [name]);
    return res;
  }

  getAllPoints() async {
    final db = await dbp.database;
    var res = await db.query("points");
    List<Point> list =
    res.isNotEmpty ? res.map((c) => Point.fromMap(c)).toList() : [];
    return list;
  }

  getPoint(String name) async {
    final db = await dbp.database;
    var res =await  db.query("points", where: "name = ?", whereArgs: [name]);
    return res.isNotEmpty ? Point.fromMap(res.first) : Null ;
  }
}
