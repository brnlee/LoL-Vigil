import 'package:android_intent/android_intent.dart';
import 'package:android_intent/flag.dart';
import 'package:lolvigilmobile/models/fcmMessage.dart';
import 'package:battery_optimization/battery_optimization.dart';

void checkIgnoreBatteryOptimization() async {
  BatteryOptimization.isIgnoringBatteryOptimizations().then((isIgnoring) => {
    if (!isIgnoring)
      BatteryOptimization.openBatteryOptimizationSettings()
  });
}

void launchAlarm(Message message) {
  print("LaunchAlarm: ${message.matchup} ${message.trigger}");

  AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.RUN',
      package: 'brnlee.lolvigilmobile',
      componentName: 'brnlee.lolvigilmobile.AlarmActivity',
      arguments: {
        'matchID': message.matchID,
        'gameNumber': message.gameNumber,
        'matchup': message.matchup,
        'trigger': message.trigger
      },
      flags: [
        Flag.FLAG_ACTIVITY_NO_ANIMATION
      ]);

  intent.launch();
}
