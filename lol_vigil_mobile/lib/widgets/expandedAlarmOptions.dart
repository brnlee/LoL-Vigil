import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';

class ExpandedAlarmOptions extends StatelessWidget {
  ExpandedAlarmOptions(this._matchAlarm);

  final MatchAlarm _matchAlarm;

  saveAlarm() => _matchAlarm.save();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (int gameNumber = 1; gameNumber <= _matchAlarm.numGames; gameNumber++)
        ExpandableNotifier(
          initialExpanded: gameNumber == 1 ? true : false,
          child: ScrollOnExpand(
            child: Column(
              children: <Widget>[
                ExpandablePanel(
                  theme: ExpandableThemeData(iconColor: Theme.of(context).hintColor, hasIcon: false),
                  header: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text('Game $gameNumber'),
                        ),
                        ExpandableIcon(
                            theme: ExpandableThemeData(
                          iconColor: Theme.of(context).hintColor,
                        )),
                      ],
                    ),
                  ),
                  expanded: _GameAlarmOptions(_matchAlarm, gameNumber - 1),
                ),
              ],
            ),
          ),
        )
    ]);
  }
}

class _GameAlarmOptions extends StatefulWidget {
  _GameAlarmOptions(this._matchAlarm, this.gameNumber);

  final MatchAlarm _matchAlarm;
  final int gameNumber;

  @override
  _GameAlarmOptionsState createState() => _GameAlarmOptionsState();
}

class _GameAlarmOptionsState extends State<_GameAlarmOptions> {
  Trigger _alarmTrigger;
  double _delay;
  GameAlarm _gameAlarm;

  @override
  void initState() {
    _gameAlarm = widget._matchAlarm.alarms[widget.gameNumber];
    _alarmTrigger = _gameAlarm.alarmTrigger;
    _delay = _gameAlarm.delay;
    super.initState();
  }

  onTriggerChanged(Trigger trigger) {
    _gameAlarm.alarmTrigger = trigger;
    widget._matchAlarm.save();
    setState(() => _alarmTrigger = trigger);
  }

  onDelayChanged(double value) {
    _gameAlarm.delay = value;
    widget._matchAlarm.save();
    this.setState(() => _delay = value);
  }

  @override
  Widget build(BuildContext context) {
    _alarmTrigger = _gameAlarm.alarmTrigger;
    return Column(
      children: <Widget>[
        RadioListTile(
          title: const Text('Off'),
          value: Trigger.Off,
          groupValue: _alarmTrigger,
          dense: true,
          onChanged: onTriggerChanged,
        ),
//        RadioListTile(
//          title: const Text('Champion Select Begins'),
//          value: Trigger.ChampionSelectBegins,
//          groupValue: _alarmTrigger,
//          dense: true,
//          onChanged: onTriggerChanged,
//        ),
        RadioListTile(
          title: const Text('Game Begins'),
          value: Trigger.GameBegins,
          groupValue: _alarmTrigger,
          dense: true,
          onChanged: onTriggerChanged,
        ),
        RadioListTile(
          title: const Text('First Blood'),
          value: Trigger.FirstBlood,
          groupValue: _alarmTrigger,
          dense: true,
          onChanged: onTriggerChanged,
        ),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 24),
            child: Row(
              children: <Widget>[
                Text('Delay'),
                Expanded(
                  child: Slider(
                    label: '${_gameAlarm.delay.toInt()} min',
                    min: 0,
                    max: 20,
                    divisions: 20,
                    value: _delay,
                    onChanged: _alarmTrigger == Trigger.Off ? null : onDelayChanged,
                  ),
                )
              ],
            ))
      ],
    );
  }
}
