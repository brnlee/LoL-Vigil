import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';

class ExpandedAlarmOptions extends StatefulWidget {
  ExpandedAlarmOptions(this.alarm, this.numMatches);

  final MatchAlarm alarm;
  final int numMatches;

  @override
  _ExpandedAlarmOptionsState createState() => _ExpandedAlarmOptionsState();
}

class _ExpandedAlarmOptionsState extends State<ExpandedAlarmOptions> {
  @override
  Widget build(BuildContext context) {
    if (widget.numMatches == 1) return _GameAlarmOptions(1);
    return Column(children: [
      for (int i = 1; i <= widget.numMatches; i++)
        ExpandableNotifier(
          initialExpanded: i == 1 ? true : false,
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
                          child: Text('Game $i'),
                        ),
                        ExpandableIcon(
                            theme: ExpandableThemeData(
                          iconColor: Theme.of(context).hintColor,
                        )),
                      ],
                    ),
                  ),
                  expanded: _GameAlarmOptions(i),
                ),
              ],
            ),
          ),
        )
    ]);
  }
}

enum options { off, champSelectBegins, gameBegins }

class _GameAlarmOptions extends StatefulWidget {
  _GameAlarmOptions(this._gameNumber);

  final int _gameNumber;

  @override
  _GameAlarmOptionsState createState() => _GameAlarmOptionsState();
}

class _GameAlarmOptionsState extends State<_GameAlarmOptions> {
  Trigger _option;
  double _delay = 0;

  @override
  Widget build(BuildContext context) {
    _option = _option ?? (widget._gameNumber == 1 ? Trigger.ChampionSelectBegins : Trigger.Off);
    return Column(
      children: <Widget>[
        RadioListTile(
          title: const Text('Off'),
          value: Trigger.Off,
          groupValue: _option,
          dense: true,
          onChanged: (Trigger value) {
            setState(() {
              _option = value;
            });
          },
        ),
        RadioListTile(
          title: const Text('Champion Select Begins'),
          value: Trigger.ChampionSelectBegins,
          groupValue: _option,
          dense: true,
          onChanged: (Trigger value) {
            setState(() {
              _option = value;
            });
          },
        ),
        RadioListTile(
          title: const Text('Game Begins'),
          value: Trigger.GameBegins,
          groupValue: _option,
          dense: true,
          onChanged: (Trigger value) {
            setState(() {
              _option = value;
            });
          },
        ),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 24),
            child: Row(
              children: <Widget>[
                Text('Delay'),
                Expanded(
                  child: Slider(
                    label: '${_delay.toInt()} min',
                    min: 0,
                    max: 20,
                    divisions: 20,
                    value: _delay,
                    onChanged: _option == Trigger.Off
                        ? null
                        : (double value) {
                            setState(() => _delay = value);
                          },
                  ),
                )
              ],
            ))
      ],
    );
  }
}
