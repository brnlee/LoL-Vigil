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
    onBackgroundMessage: backgroundFCMMessageHandler,
  );

  runApp(App());
}

handleFcmMessage(Map<String, dynamic> fcmMessage) async {
  print(fcmMessage);

  if (fcmMessage.containsKey('data')) {
    dynamic data = fcmMessage['data'];
    try {
      Message message = Message.fromJson(json.decode(data["message"]));
      launchAlarm(message);

      Box alarmsBox = await Hive.openBox('MatchAlarms');
      MatchAlarm alarm = alarmsBox.get(message.matchID);
      alarm.alarms[int.parse(message.gameNumber) - 1].alarmTrigger = Trigger.Off;
      alarm.save();
    } catch (e) {
      print("Error parsing Message and launching Alarm: $e");
    }
  }
}

Future<dynamic> backgroundFCMMessageHandler(Map<String, dynamic> fcmMessage) async {
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MatchAlarmAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GameAlarmAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TriggerAdapter());

  await Hive.initFlutter();

  handleFcmMessage(fcmMessage);
}
