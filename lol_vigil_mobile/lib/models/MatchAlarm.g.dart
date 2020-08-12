// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MatchAlarm.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TriggerAdapter extends TypeAdapter<Trigger> {
  @override
  final int typeId = 3;

  @override
  Trigger read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Trigger.Off;
      case 1:
        return Trigger.ChampionSelectBegins;
      case 2:
        return Trigger.GameBegins;
      case 3:
        return Trigger.FirstBlood;
      default:
        return null;
    }
  }

  @override
  void write(BinaryWriter writer, Trigger obj) {
    switch (obj) {
      case Trigger.Off:
        writer.writeByte(0);
        break;
      case Trigger.ChampionSelectBegins:
        writer.writeByte(1);
        break;
      case Trigger.GameBegins:
        writer.writeByte(2);
        break;
      case Trigger.FirstBlood:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriggerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MatchAlarmAdapter extends TypeAdapter<MatchAlarm> {
  @override
  final int typeId = 1;

  @override
  MatchAlarm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchAlarm(
      fields[0] as String,
      fields[2] as int,
    )
      ..isOn = fields[1] as bool
      ..alarms = (fields[3] as List)?.cast<GameAlarm>();
  }

  @override
  void write(BinaryWriter writer, MatchAlarm obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.matchID)
      ..writeByte(1)
      ..write(obj.isOn)
      ..writeByte(2)
      ..write(obj.numGames)
      ..writeByte(3)
      ..write(obj.alarms);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchAlarmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GameAlarmAdapter extends TypeAdapter<GameAlarm> {
  @override
  final int typeId = 2;

  @override
  GameAlarm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameAlarm(
      fields[0] as int,
    )
      ..alarmTrigger = fields[1] as Trigger
      ..delay = fields[2] as double;
  }

  @override
  void write(BinaryWriter writer, GameAlarm obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.gameNumber)
      ..writeByte(1)
      ..write(obj.alarmTrigger)
      ..writeByte(2)
      ..write(obj.delay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameAlarmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
