// based on this tutorial:
// https://itnext.io/build-a-compass-app-in-flutter-b49a78aa951d

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(Compass());
}

class Compass extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
        title: 'Weltmetropole Höpfigheim',
        theme: CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.indigo,
            barBackgroundColor: Colors.blueAccent,
            scaffoldBackgroundColor: Colors.indigo),
        home: CupertinoPageScaffold(
          navigationBar:
              CupertinoNavigationBar(middle: Text("Weltmetropole Höpfigheim")),
          child: CompassWidget(),
        ));
    // return MaterialApp(
    //   title: 'Flutter Demo',
    //   theme: ThemeData(
    //     // This is the theme of your application.
    //     //
    //     // Try running your application with "flutter run". You'll see the
    //     // application has a blue toolbar. Then, without quitting the app, try
    //     // changing the primarySwatch below to Colors.green and then invoke
    //     // "hot reload" (press "r" in the console where you ran "flutter run",
    //     // or simply save your changes to "hot reload" in a Flutter IDE).
    //     // Notice that the counter didn't reset back to zero; the application
    //     // is not restarted.
    //     primarySwatch: Colors.blue,
    //     // This makes the visual density adapt to the platform that you run
    //     // the app on. For desktop platforms, the controls will be smaller and
    //     // closer together (more dense) than on mobile platforms.
    //     visualDensity: VisualDensity.adaptivePlatformDensity,
    //   ),
    //   home: CompassWidget(title: 'Flutter Demo Home Page'),
    // );
  }
}

class CompassWidget extends StatefulWidget {
  CompassWidget({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _CompassWidgetState createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget> {
  double _heading = 0;
  Position currentPosition;

  StreamSubscription<Position> positionStream;

  String get _readout =>
      _heading.round() % 360 == 0 ? "0°" : _heading.toStringAsFixed(0) + '°';

  void initState() {
    super.initState();
    FlutterCompass.events.listen(_onData);
    positionStream = getPositionStream(desiredAccuracy: LocationAccuracy.high)
        .listen((Position position) {
      setState(() {
        currentPosition = position;
      });
    });
  }

  void _onData(double x) => setState(() {
        if (currentPosition == null) {
          _heading = x;
        } else {
          // _heading = x -
          //     _getOffsetFromNorth(
          //         48.994719, 9.208169, 48.981298, 9.239052); //Test
          _heading = x -
              _getOffsetFromNorth(currentPosition.latitude, currentPosition.longitude,
                  48.981298, 9.239052); //Jonas Poolmitte
          // _heading = x -
          //     _getOffsetFromNorth(
          //         currentPosition.latitude,
          //         currentPosition.longitude,
          //         48.994719,
          //         9.208169); //Markus Garten
        }
        _heading = _heading < 0 ? _heading + 360 : _heading;
      });

  double _getOffsetFromNorth(double currentLat, double currentLong,
      double targetLat, double targetLong) {
    double y =
        sin((targetLong - currentLong) / 180 * pi) * cos(targetLat / 180 * pi);
    double x = cos(currentLat / 180 * pi) * sin(targetLat / 180 * pi) -
        sin(currentLat / 180 * pi) *
            cos(targetLat / 180 * pi) *
            cos((targetLong - currentLong) / 180 * pi);
    double z = atan2(y, x);
    return (z * 180 / pi + 360) % 360;
  }

  final TextStyle _style =
      TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold);

  Widget build(BuildContext context) {
    // return FutureBuilder(future: checkPermission(), builder: (BuildContext context, AsyncSnapshot<LocationPermission> snapshot) {
    //   if (snapshot.hasData) {
    //     if (snapshot.data == LocationPermission.denied || snapshot.data == LocationPermission.deniedForever) {
    //       requestPermission();
    //     }
    //     if (snapshot.data == LocationPermission.always || snapshot.data == LocationPermission.whileInUse) {
    //       return CustomPaint(
    //           foregroundPainter: CompassPainter(angle: _heading),
    //           child: Center(child: Text(_readout, style: _style)));
    //     }
    //   } else if (snapshot.hasError) {
    //     return Text("Kann nicht checken, ob Standort-Berechtigung erteilt ist. Sehr strange! Bitte Dev kontaktieren :P", style: TextStyle(color: Colors.red, fontSize: 40, fontWeight: FontWeight.bold));
    //   } else {
    //     return CupertinoActivityIndicator();
    //   }
    //   return CupertinoActivityIndicator();
    // },);
    return CustomPaint(
        foregroundPainter: CompassPainter(angle: _heading),
        child: Center(child: Text(_readout, style: _style)));
  }
}

class CompassPainter extends CustomPainter {
  CompassPainter({@required this.angle}) : super();

  final double angle;

  double get rotation => -2 * pi * (angle / 360);

  Paint get _brush => new Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  void paint(Canvas canvas, Size size) {
    Paint circle = _brush..color = Colors.black;

    Paint needle = _brush..color = Colors.red[400];

    double radius = min(size.width / 2.2, size.height / 2.2);
    Offset center = Offset(size.width / 2, size.height / 2);
    Offset start = Offset.lerp(Offset(center.dx, radius), center, .4);
    Offset end = Offset.lerp(Offset(center.dx, radius), center, 0.1);

    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawLine(start, end, needle);
    canvas.drawCircle(center, radius, circle);
  }

  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
