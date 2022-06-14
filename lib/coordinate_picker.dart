/*
Copyright 2021, 2022 Province of British Columbia

This file is part of FBP Go.

FBP Go is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

FBP Go is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with 
FBP Go. If not, see <https://www.gnu.org/licenses/>.
*/
import 'dart:developer';
import 'package:fire_behaviour_app/fbp_results.dart';
import 'package:fire_behaviour_app/persist.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'fancy_slider.dart';
import 'fire.dart';
import 'global.dart';

class Coordinate {
  double latitude;
  double longitude;
  double altitude;

  Coordinate(
      {required this.latitude,
      required this.longitude,
      required this.altitude});

  @override
  String toString() {
    return 'Coordinate{latitude: $latitude, longitude: $longitude, elevation: $altitude}';
  }
}

Coordinate createDefaultCoordinate() {
  return Coordinate(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      altitude: defaultAltitude);
}

class CoordinatePickerState extends State<CoordinatePicker> {
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _elevationController = TextEditingController();

  late Coordinate _coordinate;

  _getPosition() async {
    log('calling _getPosition');
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      log('got position $position');
      return position;
    } catch (e) {
      log('error getting position $e');
    }
  }

  void _setLatitude(latitude) {
    // Limit to 2 decimal places for consistent input.
    _coordinate.latitude = roundDouble(latitude, 2);
    persistSetting('latitude', _coordinate.latitude);
  }

  void _setLongitude(longitude) {
    // Limit to 2 decimal places for consistent input.
    _coordinate.longitude = roundDouble(longitude, 2);
    persistSetting('longitude', _coordinate.longitude);
  }

  void _setAltitude(value) {
    // We pin the altitude to acceptable ranges. The altitude could come back as a negative number,
    // WGS84 projection gives some locations on earth, that are above sea level, a negative number.
    double altitude = pinAltitude(value);
    // Only need integer level accuracy.
    _coordinate.altitude = altitude.roundToDouble();
    persistSetting('altitude', _coordinate.altitude);
  }

  void _updatePosition() {
    Permission.location.request().then((request) => {
          if (request.isGranted)
            {
              _getPosition().then((position) {
                if (mounted) {
                  setState(() {
                    _setLatitude(position.latitude);
                    _setLongitude(position.longitude);
                    _setAltitude(position.altitude);
                    widget.onChanged(_coordinate);
                    _updateCoordinateControllers();
                  });
                }
              })
            }
        });
  }

  @override
  void initState() {
    super.initState();
    // We only load the position if the user asks for it!
    // _updatePosition();
    _coordinate = widget.coordinate;
    _updateCoordinateControllers();
  }

  void _updateCoordinateControllers() {
    _latitudeController.text = _coordinate.latitude.toStringAsFixed(2);
    _longitudeController.text = _coordinate.longitude.toStringAsFixed(2);
    _elevationController.text = _coordinate.altitude.toStringAsFixed(0);
  }

  String? get _elevationErrorText {
    final text = _elevationController.value.text;

    if (text.isEmpty) {
      return 'Can\'t be empty';
    }
    if (double.tryParse(text) != null) {
      double elevation = double.parse(text);
      if (elevation < minAltitude) {
        return 'Min: ${formatNumber(minAltitude, digits: 0)}';
      } else if (elevation > maxAltitude) {
        return 'Max: ${formatNumber(maxAltitude, digits: 0)}';
      }
    } else {
      return 'Not a number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(fontSize: fontSize);
    const TextStyle textStyleBold =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);
    return Column(
      children: [
        Row(
          children: [
            // TODO: If this is going to stick, you need to make the text flex, and the slider flex consants somewhere else.
            // TODO: If this is going to stick, you need to make some common code for making the lable and the slider things.
            Expanded(
                flex: 5,
                child: Column(children: [
                  Row(children: const [
                    Text('Elevation', style: textStyle),
                    Text(':', style: textStyle)
                  ]),
                  Row(children: [
                    Text(_coordinate.altitude.toStringAsFixed(0),
                        style: textStyleBold),
                    const Text('(m)', style: textStyle)
                  ])
                ])),
            Expanded(
                flex: 10,
                child: FancySliderWidget(
                  value: _coordinate.altitude,
                  min: minAltitude,
                  max: maxAltitude,
                  divisions: 100,
                  activeColor: Colors.green,
                  label: '${_coordinate.altitude.toStringAsFixed(0)} m',
                  onChanged: (value) {
                    _setAltitude(value);
                    widget.onChanged(_coordinate);
                    _elevationController.text =
                        _coordinate.altitude.toStringAsFixed(0);
                  },
                ))
          ],
        ),
        Row(
          children: [
            //     // latitude Field
            Expanded(
                child: TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                  labelText: "Latitude", labelStyle: textStyle),
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              onChanged: (value) {
                if (double.tryParse(value) != null) {
                  double latitude = double.parse(value);
                  if (latitude >= -90 && latitude <= 90) {
                    setState(() {
                      _setLatitude(latitude);
                      widget.onChanged(_coordinate);
                    });
                  }
                }
              },
            )),
            // longitude Field
            Expanded(
                child: TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                  labelText: "Longitude", labelStyle: textStyle),
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              onChanged: (value) {
                if (double.tryParse(value) != null) {
                  double longitude = double.parse(value);
                  if (longitude >= -180 && longitude.abs() <= 180) {
                    _setLongitude(longitude);
                    widget.onChanged(_coordinate);
                  }
                }
              },
            )),
            Expanded(
                child: TextField(
              controller: _elevationController,
              decoration: InputDecoration(
                  labelText: "Elevation (m)",
                  labelStyle: textStyle,
                  errorText: _elevationErrorText),
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              onChanged: (value) {
                print('onChanged: ${value}');
                if (double.tryParse(value) != null) {
                  var altitude = double.parse(value);
                  _setAltitude(altitude);
                  widget.onChanged(_coordinate);
                } else {
                  print('cannot parse that');
                  _setAltitude(minAltitude);
                  widget.onChanged(_coordinate);
                }
              },
            )),
            Expanded(
                child: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: () {
                      _updatePosition();
                    }))
          ],
        )
      ],
    );
  }
}

class CoordinatePicker extends StatefulWidget {
  final Function onChanged;
  final Coordinate coordinate;

  const CoordinatePicker(
      {Key? key, required this.onChanged, required this.coordinate})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CoordinatePickerState();
  }
}
