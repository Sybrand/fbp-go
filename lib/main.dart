import 'fbp_advanced.dart';
import 'package:flutter/material.dart';
import 'cffdrs/fbp_calc.dart';
import 'fbp_basic.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: 'Fire Behaviour Prediction', home: HomePage());
  }
}

String getSecondaryText(FireBehaviourPredictionPrimary? prediction) {
  if (prediction != null && prediction.secondary != null) {
    return prediction.secondary.toString();
  }
  return '';
}

enum Section { basic, advanced, fwi, about }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  Section _selectedSection = Section.basic;

  String _getSectionText() {
    switch (_selectedSection) {
      case Section.basic:
        return 'Basic FBP';
      case Section.advanced:
        return 'Advanced FBP';
      case Section.fwi:
        return 'Fire Weather Index';
      case Section.about:
        return 'About';
      default:
        throw Exception('Unknown section');
    }
  }

  _getSelectedSection(Section _section) {
    switch (_section) {
      case (Section.about):
        return const Text('About');
      case (Section.basic):
        return Center(
            child: SingleChildScrollView(
                child: Column(
          children: const [BasicFireBehaviourPredictionForm()],
        )));
      case (Section.advanced):
        return Center(
            child: SingleChildScrollView(
                child: Column(
          children: const [AdvancedFireBehaviourPredictionForm()],
        )));
      case (Section.fwi):
        return const Text('FWI');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getSectionText())),
      body: _getSelectedSection(_selectedSection),
      drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Text('Fire Behaviour Prediction'),
            decoration: BoxDecoration(color: Colors.blue),
          ),
          ListTile(
              title: const Text('Basic Fire Behaviour Prediction (FBP)'),
              onTap: () {
                _changeSection(Section.basic);
              }),
          ListTile(
              title: const Tooltip(
                  message: 'FBP for nerds',
                  child: Text('Advanced Fire Behaviour Prediction (FBP)')),
              onTap: () {
                _changeSection(Section.advanced);
              }),
          ListTile(
              title: const Text('Fire Weather Index (FWI)'),
              onTap: () {
                _changeSection(Section.fwi);
              }),
          ListTile(
              title: const Text('About'),
              onTap: () {
                _changeSection(Section.about);
              })
        ],
      )),
    );
  }

  void _changeSection(Section section) {
    setState(() {
      _selectedSection = section;
    });
    Navigator.pop(context);
  }
}
