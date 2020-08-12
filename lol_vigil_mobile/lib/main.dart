import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';
import 'package:lolvigilmobile/utils/androidHelpers.dart';
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

String firebaseToken;

void main() async {
  Hive.registerAdapter(MatchAlarmAdapter());
  Hive.registerAdapter(GameAlarmAdapter());
  Hive.registerAdapter(TriggerAdapter());
  await Hive.initFlutter();
  await Hive.openBox('Leagues');
  await Hive.openBox('MatchAlarms');

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  firebaseToken = await _firebaseMessaging.getToken();
  print(firebaseToken);

  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
      print("onMessage: $message");
      if (message.containsKey('data')) launchAlarm(message['data']);
    },
    onBackgroundMessage: myBackgroundMessageHandler,
    onLaunch: (Map<String, dynamic> message) async {
      print("onLaunch: $message");
    },
    onResume: (Map<String, dynamic> message) async {
      print("onResume: $message");
    },
  );

  runApp(App());
}


Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  print(message);

  if (message.containsKey('data')) launchAlarm(message['data']);
}

