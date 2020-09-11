// based on this tutorial:
// https://itnext.io/build-a-compass-app-in-flutter-b49a78aa951d

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as IMG;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(Compass());
}

class Compass extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Weltmetropole Höpfigheim',
      theme: CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.indigo,
          barBackgroundColor: Colors.indigo[900],
          scaffoldBackgroundColor: Colors.black),
      home: CupertinoPageScaffold(
        navigationBar:
            CupertinoNavigationBar(middle: Text("Weltmetropole Höpfigheim")),
        child: CompassWidget(),
      ),
    );
  }
}

class CompassWidget extends StatefulWidget {
  CompassWidget({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _CompassWidgetState createState() => _CompassWidgetState();
}

class _CompassWidgetState extends State<CompassWidget> {
  ui.Image _image;

  double _distance = 0;
  double _heading = 0;
  Position currentPosition;

  StreamSubscription<Position> positionStream;
  StreamSubscription compassStream;

  String get _readout =>
      _heading.round() % 360 == 0 ? "0°" : _heading.toStringAsFixed(0) + '°';

  void initState() {
    super.initState();

    loadUiImage("assets/Wappen.png");

    compassStream = FlutterCompass.events.listen(_onData);
    positionStream = getPositionStream(desiredAccuracy: LocationAccuracy.high)
        .listen((Position position) {
      setState(() {
        currentPosition = position;
      });
    });
  }

  void dispose() {
    super.dispose();

    compassStream.cancel();
    positionStream.cancel();
  }

  void _onData(double x) => setState(() {
        if (currentPosition == null) {
          _heading = x;
          _distance = 0;
        } else {
          // _heading = x -
          //     _getOffsetFromNorth(
          //         48.994719, 9.208169, 48.981298, 9.239052); //Test
          _heading = x -
              _getOffsetFromNorth(
                  currentPosition.latitude,
                  currentPosition.longitude,
                  48.981298,
                  9.239052); //Jonas Poolmitte
          _distance = _getDistance(currentPosition.latitude,
              currentPosition.longitude, 48.981298, 9.239052);
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

  double _getDistance(double currentLat, double currentLong, double targetLat,
      double targetLong) {
    const R = 6371e3; // metres
    double currentLatRad = currentLat * pi / 180; // φ, λ in radians
    double targetLatRad = targetLat * pi / 180;
    double calcLatRad = (targetLat - currentLat) * pi / 180;
    double calcLongRad = (targetLong - currentLong) * pi / 180;

    double a = sin(calcLatRad / 2) * sin(calcLatRad / 2) +
        cos(currentLatRad) *
            cos(targetLatRad) *
            sin(calcLongRad / 2) *
            sin(calcLongRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c / 1000; // in km
  }

  final TextStyle _style =
      TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold);

  Future<ui.Image> loadUiImage(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final IMG.Image image = IMG.decodeImage(Uint8List.view(data.buffer));
    final Completer<ui.Image> completer = Completer();
    final IMG.Image resized = IMG.copyResize(image, width: 50);
    final List<int> resizedBytes = IMG.encodePng(resized);
    ui.decodeImageFromList(resizedBytes, (ui.Image img) {
      _image = img;
      return completer.complete(img);
    });
    return completer.future;
  }

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

    return _image == null
        ? FutureBuilder<ui.Image>(
            future: loadUiImage("assets/Wappen_gedreht.png"),
            builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return new Text('Image loading...');
                default:
                  if (!snapshot.hasError) {
                    _image = snapshot.data;
                  }
                  return CustomPaint(
                    foregroundPainter: CompassPainter(
                      angle: _heading,
                      distance: _distance,
                      image: _image,
                    ),
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_readout, style: _style),
                          _distance > 100
                              ? Text('${_distance.toStringAsFixed(0)} km',
                                  style: _style)
                              : Text('${_distance.toStringAsFixed(2)} km',
                                  style: _style),
                        ],
                      ),
                    ),
                  );
              }
            },
          )
        : CustomPaint(
            foregroundPainter: CompassPainter(
              angle: _heading,
              image: _image,
            ),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_readout, style: _style),
                  _distance > 100
                      ? Text('${_distance.toStringAsFixed(0)} km',
                          style: _style)
                      : Text('${_distance.toStringAsFixed(2)} km',
                          style: _style),
                ],
              ),
            ),
          );
  }
}

class CompassPainter extends CustomPainter {
  CompassPainter({
    @required this.angle,
    @required this.distance,
    @required this.image,
  }) : super();

  final double distance;
  final double angle;
  final ui.Image image;

  double get rotation => -2 * pi * (angle / 360);

  Paint get _brush => new Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  void paint(Canvas canvas, Size size) {
    Paint circle = _brush..color = Colors.white;

    Paint needle = _brush..color = Colors.red[800];

    double radius = min(size.width / 2.2, size.height / 2.2);
    Offset center = Offset(size.width / 2, size.height / 2);
    Offset start = Offset.lerp(Offset(center.dx, radius), center, .4);
    Offset end = Offset.lerp(Offset(center.dx, radius), center, 0.1);
    Offset imageOffset =
        Offset.lerp(Offset(center.dx - 50, radius - 200), center, 0.5);

    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    if (image != null) {
      canvas.drawImage(image, imageOffset, new Paint());
    } else {
      canvas.drawLine(start, end, needle);
    }
    canvas.drawCircle(center, radius, circle);
  }

  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
