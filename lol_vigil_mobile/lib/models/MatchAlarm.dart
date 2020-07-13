import 'package:hive/hive.dart';
part 'MatchAlarm.g.dart';

@HiveType(typeId: 1)
class MatchAlarm {
  MatchAlarm(this.matchID, this.isOn, [this.alarms]);

  @HiveField(0)
  String matchID;
  @HiveField(1)
  bool isOn;
  @HiveField(2)
  List<GameAlarm> alarms;

  @override
  String toString() {
    String str = "$matchID\t$isOn\n";
    alarms.forEach((alarm) => str += "\t${alarm.toString()}\n");
    return str;
  }
}

@HiveType(typeId: 2)
class GameAlarm {
  GameAlarm(this.gameNumber, this.alarmTrigger, this.delay);

  @HiveField(0)
  int gameNumber;
  @HiveField(1)
  Trigger alarmTrigger;
  @HiveField(2)
  int delay;

  @override
  String toString() => "$gameNumber\t$alarmTrigger\t$delay";
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
