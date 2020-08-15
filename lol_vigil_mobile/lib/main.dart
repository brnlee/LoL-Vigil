import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';
import 'package:lolvigilmobile/models/fcmMessage.dart';
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
    onMessage: (Map<String, dynamic> message) async => handleFcmMessage(message),
    onBackgroundMessage: handleFcmMessage,
  );

  runApp(App());
}

Future<dynamic> handleFcmMessage(Map<String, dynamic> fcmMessage) {
  print(fcmMessage);

  if (fcmMessage.containsKey('data')) {
    dynamic data = fcmMessage['data'];
    try {
      Message message = Message.fromJson(json.decode(data["message"]));
      launchAlarm(message);

      // Switch the game's alarm trigger to Off
      Box alarmsBox = Hive.box('MatchAlarms');
      MatchAlarm alarm = alarmsBox.get(message.matchID);
      alarm.alarms[message.gameNumber-1].alarmTrigger = Trigger.Off;
      alarm.save();
    } catch (e) {
      print("Error parsing Message and launching Alarm: $e");
    }
  }

  return null;
}
