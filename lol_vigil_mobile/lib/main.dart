import 'package:flutter/material.dart';
import 'package:lolvigilmobile/widgets/matchList.dart';

void main() => runApp(App());

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
