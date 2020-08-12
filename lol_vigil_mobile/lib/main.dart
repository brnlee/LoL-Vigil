import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';
import 'package:lolvigilmobile/widgets/matchList.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_intent/android_intent.dart';

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
      _getBatteryLevel();
      print("onMessage: $message");
      AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.RUN',

        // Replace this by your package name.
        package: 'brnlee.lolvigilmobile',

        // Replace this by your package name followed by the activity you want to open.
        // The default activity provided by Flutter is MainActivity, but you can check
        // this in AndroidManifest.xml.
        componentName: 'brnlee.lolvigilmobile.AlarmActivity',
      );

      await intent.launch();
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

String firebaseToken;

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
//  _getBatteryLevel();
  print(message);

  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
    print(data);
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }
  AndroidIntent intent = AndroidIntent(
    action: 'android.intent.action.RUN',

    // Replace this by your package name.
    package: 'brnlee.lolvigilmobile',

    // Replace this by your package name followed by the activity you want to open.
    // The default activity provided by Flutter is MainActivity, but you can check
    // this in AndroidManifest.xml.
    componentName: 'brnlee.lolvigilmobile.AlarmActivity',
  );

  intent.launch();
  // Or do other work.
}

Future<void> _getBatteryLevel() async {
  const platform = const MethodChannel('brnlee.lolvigilmobile/alarmScreen');
  print("GETTING BATTERY LEVEL");
  String batteryLevel;
  try {
    final int result = await platform.invokeMethod('getBatteryLevel');
    batteryLevel = 'Battery level at $result % .';
  } on PlatformException catch (e) {
    batteryLevel = "Failed to get battery level: '${e.message}'.";
  }

  print("BATTERY LEVEL: $batteryLevel");
}