import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/widgets/matchList.dart';
import 'package:hive_flutter/hive_flutter.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LoL Vigil",
      home: MatchList(),
      theme: ThemeData.dark(),
    );
  }
}

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('Leagues');
  await Hive.openLazyBox('MatchAlarms');
  runApp(App());
}
