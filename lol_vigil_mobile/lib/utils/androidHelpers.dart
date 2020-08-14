import 'package:android_intent/android_intent.dart';
import 'package:android_intent/flag.dart';
import 'package:lolvigilmobile/models/fcmMessage.dart';

void launchAlarm(Message message) {
  print("LaunchAlarm: ${message.matchup} ${message.trigger}");

  AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.RUN',
      package: 'brnlee.lolvigilmobile',
      componentName: 'brnlee.lolvigilmobile.AlarmActivity',
      arguments: {'matchup': message.matchup, 'trigger': message.trigger},
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_NO_ANIMATION]);

  intent.launch();
}