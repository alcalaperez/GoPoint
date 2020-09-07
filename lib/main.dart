import 'package:flutter/material.dart';
import 'package:gopoint/screens/Home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoPoint',
      theme: ThemeData(
        primarySwatch: Colors.orange,
          primaryTextTheme: TextTheme(
              headline6: TextStyle(
                  color: Colors.white
              )
          )
      ),
      home: MyHomePage(title: 'GoPoint'),
    );
  }
}