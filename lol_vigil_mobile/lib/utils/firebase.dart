import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';
import 'package:lolvigilmobile/models/fcmMessage.dart';
import 'androidHelpers.dart';

Future<String> initFirebase() async {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> fcmMessage) async {
      Message message = Message.parseFcmMessage(fcmMessage);
      if (message != null) {
        launchAlarm(message);

        Box alarmsBox = Hive.box('MatchAlarms');
        MatchAlarm alarm = alarmsBox.get(message.matchID);
        alarm.alarms[int.parse(message.gameNumber) - 1].alarmTrigger = Trigger.Off;
        alarm.save();
      }
    },
    onBackgroundMessage: backgroundFCMMessageHandler,
  );

  return _firebaseMessaging.getToken();
}

Future<dynamic> backgroundFCMMessageHandler(Map<String, dynamic> fcmMessage) async {
  Message message = Message.parseFcmMessage(fcmMessage);
  if (message != null) {
    launchAlarm(message);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MatchAlarmAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GameAlarmAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TriggerAdapter());
    await Hive.initFlutter();

    Box alarmsToUpdateBox = await Hive.openBox('AlarmsToUpdate');
    alarmsToUpdateBox.put(message.matchID, message.gameNumber);
    alarmsToUpdateBox.close();
  }
}
