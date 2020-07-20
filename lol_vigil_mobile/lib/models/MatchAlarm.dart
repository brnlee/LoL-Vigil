import 'package:hive/hive.dart';
part 'MatchAlarm.g.dart';

@HiveType(typeId: 1)
class MatchAlarm extends HiveObject{
  MatchAlarm(this.matchID, this.numGames){
    if (alarms == null){
      alarms = List<GameAlarm>.generate(numGames, (index) => GameAlarm(index+1));
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
    String str = "$matchID\t$isOn\n";
    if (alarms != null) alarms.forEach((alarm) => str += "\t${alarm.toString()}\n");
    return str;
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
