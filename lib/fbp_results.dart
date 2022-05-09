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
import 'package:flutter/material.dart';

import 'cffdrs/fbp_calc.dart';
import 'fire.dart';
import 'fire_widgets.dart';
import 'global.dart';

String formatNumber(double? number, {int digits = 2}) {
  if (number == null) {
    return '';
  }
  return number.toStringAsFixed(digits);
}

abstract class Group {
  Group({required this.heading, this.isExpanded = false});
  String heading;
  bool isExpanded;

  Row _buildRow(String value, String label, Color? color) {
    TextStyle valueStyle = TextStyle(
        color: color, fontWeight: FontWeight.bold, fontSize: fontSize);
    TextStyle labelStyle = TextStyle(color: color, fontSize: fontSize);
    return Row(children: [
      Expanded(
          flex: 5,
          child: Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child:
                  Text(value, textAlign: TextAlign.right, style: valueStyle))),
      Expanded(flex: 6, child: Text(label, style: labelStyle)),
    ]);
  }

  Widget buildBody(FireBehaviourPredictionInput input,
      FireBehaviourPredictionPrimary prediction, double minutes);

  Container buildContainer(List<Widget> children) {
    return Container(color: Colors.white, child: Column(children: children));
  }
}

class SecondaryFireBehaviourGroup extends Group {
  SecondaryFireBehaviourGroup({required String heading})
      : super(heading: heading);

  @override
  Widget buildBody(FireBehaviourPredictionInput input,
      FireBehaviourPredictionPrimary prediction, double minutes) {
    TextStyle textStyle = getTextStyle(prediction.FD);
    return buildContainer([
      // Planned ignition
      _buildRow('${(prediction.SFC).toStringAsFixed(0)} (kg/\u33A1)',
          'Surface fuel consumption', textStyle.color),
      _buildRow('${(prediction.CFC).toStringAsFixed(0)} (kg/\u33A1)',
          'Crown fuel consumption', textStyle.color),
      _buildRow('${(prediction.TFC).toStringAsFixed(0)} (kg/\u33A1)',
          'Total fuel consumption', textStyle.color),
      _buildRow(
          '${(prediction.secondary?.FTFC)?.toStringAsFixed(0)} (kg/\u33A1)',
          'Total fuel consumption - flank',
          textStyle.color),
      _buildRow(
          '${(prediction.secondary?.BTFC)?.toStringAsFixed(0)} (kg/\u33A1)',
          'Total fuel consumption - back',
          textStyle.color),
      // Fire growth potential
      _buildRow('${prediction.WSV.toStringAsFixed(0)} (km/h)',
          'Net effective wind speed', textStyle.color),
      _buildRow(
          '${degreesToCompassPoint(prediction.RAZ)} ${prediction.RAZ.toStringAsFixed(1)}\u00B0',
          'Net effective wind direction',
          textStyle.color),
      // Spread distance
      _buildRow('${formatNumber(prediction.secondary?.RSO)} m/min',
          'Surface fire rate of spread', textStyle.color),
      _buildRow(formatNumber(prediction.secondary?.LB),
          'Length to breadth ratio', textStyle.color),
      _buildRow(formatNumber(prediction.secondary?.DH),
          'Fire spread distance - head', textStyle.color),
      _buildRow(formatNumber(prediction.secondary?.DB),
          'Fire spread distance - flank', textStyle.color),
      _buildRow(formatNumber(prediction.secondary?.DF),
          'Fire spread distance - back', textStyle.color),
    ]);
  }
}

class PrimaryFireBehaviourGroup extends Group {
  PrimaryFireBehaviourGroup({required String heading, isExpanded = false})
      : super(heading: heading, isExpanded: isExpanded);

  @override
  Widget buildBody(FireBehaviourPredictionInput input,
      FireBehaviourPredictionPrimary prediction, double minutes) {
    double? fireSize;
    if (prediction.secondary != null) {
      fireSize = getFireSize(
          input.FUELTYPE,
          prediction.ROS,
          prediction.secondary!.BROS,
          minutes,
          prediction.CFB,
          prediction.secondary!.LB);
    }
    TextStyle textStyle = getTextStyle(prediction.FD);
    return buildContainer([
      _buildRow(
          getFireDescription(prediction.FD), 'Fire type', textStyle.color),
      _buildRow('${((prediction.CFB * 100).toStringAsFixed(0))}%',
          'Crown fraction burned', textStyle.color),
      _buildRow('${((prediction.secondary!.FCFB * 100).toStringAsFixed(0))}%',
          'Crown fraction burned - Flank', textStyle.color),
      _buildRow('${((prediction.secondary!.BCFB * 100).toStringAsFixed(0))}%',
          'Crown fraction burned - Back', textStyle.color),
      _buildRow('${((prediction.ROS).toStringAsFixed(0))} (m/min)',
          'Rate of spread', textStyle.color),
      _buildRow('${((prediction.secondary!.FROS).toStringAsFixed(0))} (m/min)',
          'Rate of spread - Flank', textStyle.color),
      _buildRow('${((prediction.secondary!.BROS).toStringAsFixed(0))} (m/min)',
          'Rate of spread - Back', textStyle.color),
      _buildRow(((prediction.ISI).toStringAsFixed(0)),
          'Initial Spread Index (ISI)', textStyle.color),
      _buildRow(
          ((getHeadFireIntensityClass(prediction.HFI)).toStringAsFixed(0)),
          'Intensity class',
          textStyle.color),
      _buildRow('${((prediction.HFI).toStringAsFixed(0))} (kW/m)',
          'Head fire intensity', textStyle.color),
      _buildRow('${((prediction.secondary!.FFI).toStringAsFixed(0))} (kW/m)',
          'Flank fire intensity', textStyle.color),
      _buildRow('${((prediction.secondary!.BFI).toStringAsFixed(0))} (kW/m)',
          'Back fire intensity', textStyle.color),
      _buildRow('${fireSize?.toStringAsFixed(1)} (ha)',
          '$minutes minute fire size', textStyle.color),
      _buildRow(
          '${degreesToCompassPoint(prediction.RAZ)} ${prediction.RAZ.toStringAsFixed(1)}\u00B0',
          'Direction of spread',
          textStyle.color),
    ]);
  }
}

List<Group> generateGroups() {
  List<Group> groups = [
    PrimaryFireBehaviourGroup(
        heading: 'Primary Fire Behaviour Outputs', isExpanded: true),
    SecondaryFireBehaviourGroup(heading: 'Secondary Fire Behaviour Outputs'),
  ];
  return groups;
}

class ResultsState extends State<ResultsStateWidget> {
  final List<Group> _groups = generateGroups();

  Row buildRow(String value, String label, Color? color) {
    TextStyle valueStyle = TextStyle(
        color: color, fontWeight: FontWeight.bold, fontSize: fontSize);
    TextStyle labelStyle = TextStyle(color: color, fontSize: fontSize);
    return Row(children: [
      Expanded(
          flex: 5,
          child: Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child:
                  Text(value, textAlign: TextAlign.right, style: valueStyle))),
      Expanded(flex: 6, child: Text(label, style: labelStyle)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = getTextStyle(widget.prediction.FD);
    // Need to have a bunch of panels:
    // https://api.flutter.dev/flutter/material/ExpansionPanelList-class.html
    return Container(
        // color: intensityClassColour,
        decoration: BoxDecoration(
            border: Border.all(color: widget.intensityClassColour),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Column(
          children: [
            ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _groups[index].isExpanded = !isExpanded;
                  });
                },
                children: _groups.map<ExpansionPanel>((Group group) {
                  return ExpansionPanel(
                      backgroundColor: widget.intensityClassColour,
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return Row(
                          children: [
                            const Spacer(),
                            Text(group.heading,
                                style: const TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold)),
                            const Spacer()
                          ],
                        );
                      },
                      body: group.buildBody(
                          widget.input, widget.prediction, widget.minutes),
                      isExpanded: group.isExpanded);
                }).toList()),
            Container(
                color: widget.intensityClassColour,
                child: Row(
                  children: const [Text('')],
                )),
            // buildRow('${widget.input.CFL} (kg/m^2)', 'Crown Fuel Load',
            //     textStyle.color),
            // buildRow('${widget.input.CBH} (m)', 'Crown to base height',
            //     textStyle.color)
          ],
        ));
  }
}

class ResultsStateWidget extends StatefulWidget {
  final FireBehaviourPredictionPrimary prediction;
  final FireBehaviourPredictionInput input;
  final int intensityClass;
  final Color intensityClassColour;
  final double minutes;
  final double? fireSize;

  const ResultsStateWidget(
      {required this.prediction,
      required this.minutes,
      required this.fireSize,
      required this.input,
      required this.intensityClass,
      required this.intensityClassColour,
      Key? key})
      : super(key: key);

  @override
  State<ResultsStateWidget> createState() => ResultsState();
}
