import 'package:hive/hive.dart';

part 'MatchAlarm.g.dart';

@HiveType(typeId: 1)
class MatchAlarm extends HiveObject {
  MatchAlarm(this.matchID, this.numGames) {
    if (alarms == null) {
      alarms = List<GameAlarm>.generate(numGames, (index) => GameAlarm(index + 1));
    }
  }

  @HiveField(0)
  String matchID;
  @HiveField(1)
  bool isOn = false;
  @HiveField(2)
  int numGames;
  @HiveField(3)
  List<GameAlarm> alarms;

  @override
  String toString() {
    String str = '$matchID\t$isOn\n';
    if (alarms != null) alarms.forEach((alarm) => str += '\t${alarm.toString()}\n');
    return str;
  }

  Map<String, dynamic> toJson() => {
        'deviceID': 1,
        'matchID': matchID,
        'gameAlarms': List<dynamic>.from(alarms.map((gameAlarm) => gameAlarm.toJson())),
      };

  toggleMatchAlarm(bool isOnValue) {
    isOn = isOnValue;
    if (!isOn) alarms.forEach((gameAlarm) => gameAlarm.alarmTrigger = Trigger.Off);
    save();
  }
}

@HiveType(typeId: 2)
class GameAlarm {
  GameAlarm(this.gameNumber) {
    this.alarmTrigger = this.gameNumber == 1 ? Trigger.ChampionSelectBegins : Trigger.Off;
  }

  @HiveField(0)
  int gameNumber;
  @HiveField(1)
  Trigger alarmTrigger;
  @HiveField(2)
  double delay = 0;

  @override
  String toString() => '$gameNumber\t$alarmTrigger\t$delay';

  Map<String, dynamic> toJson() => {
        'gameNumber': gameNumber,
        'trigger': getTriggerString(),
        'delay': delay,
      };

  String getTriggerString() {
    switch (alarmTrigger) {
      case Trigger.Off:
        return 'off';
      case Trigger.ChampionSelectBegins:
        return 'championSelectBegins';
      case Trigger.GameBegins:
        return 'gameBegins';
      default:
        return 'off';
    }
  }
}

@HiveType(typeId: 3)
enum Trigger {
  @HiveField(0)
  Off,
  @HiveField(1)
  ChampionSelectBegins,
  @HiveField(2)
  GameBegins
}
