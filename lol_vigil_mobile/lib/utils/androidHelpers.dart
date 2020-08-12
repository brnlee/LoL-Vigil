import 'dart:math';

import 'package:android_intent/android_intent.dart';
import 'package:android_intent/flag.dart';

void launchAlarm(dynamic data) {
  var randomData = data["message"] + Random().nextInt(1000).toString();
  print("DATA: $randomData");
  AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.RUN',
      package: 'brnlee.lolvigilmobile',
      componentName: 'brnlee.lolvigilmobile.AlarmActivity',
      arguments: {'match': randomData},
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_NO_ANIMATION]
      );

  intent.launch();
}
