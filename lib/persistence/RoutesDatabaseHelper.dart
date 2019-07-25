import 'package:gopoint/persistence/model/Route.dart';
import 'Database.dart';

class DBProviderRoutes {
  static final DatabaseProvider dbp = DatabaseProvider();

  newRoute(Routes newRoute) async {
    final db = await dbp.database;
    var res = await db.insert("Routes", newRoute.toMap());
    return res;
  }

  deleteRoute(String name) async {
    final db = await dbp.database;
    var res = await db.delete("Routes", where: "name = ?", whereArgs: [name]);
    return res;
  }

  getAllRoutes() async {
    final db = await dbp.database;
    var res = await db.query("Routes");
    List<Routes> list =
    res.isNotEmpty ? res.map((c) => Routes.fromMap(c)).toList() : [];
    return list;
  }

  getRoute(String name) async {
    final db = await dbp.database;
    var res =await  db.query("Routes", where: "name = ?", whereArgs: [name]);
    return res.isNotEmpty ? Routes.fromMap(res.first) : Null ;
  }
}
