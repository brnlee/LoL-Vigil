import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lolvigilmobile/models/models.dart';

class ExpandedAlarmOptions extends StatefulWidget {
  ExpandedAlarmOptions(this.alarm, this.numMatches);

  Alarm alarm;
  int numMatches;

  @override
  _ExpandedAlarmOptionsState createState() => _ExpandedAlarmOptionsState();
}

enum options { champSelectBegins, gameBegins }

class _ExpandedAlarmOptionsState extends State<ExpandedAlarmOptions> {
  options _option = options.champSelectBegins;
  double _delay = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.numMatches == 1) return buildGameAlarmOptions();
    return Column(
      children: [for (int i = 1; i <= widget.numMatches; i++) i]
          .map((i) => ExpandableNotifier(
                child: ScrollOnExpand(
                  child: Column(
                    children: <Widget>[
                      ExpandablePanel(
                        theme: ExpandableThemeData(
                            iconColor: Theme.of(context).hintColor,
                            hasIcon: false),
                        header: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
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
                        expanded: buildGameAlarmOptions(),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget buildGameAlarmOptions() {
    return Column(
      children: <Widget>[
        RadioListTile(
          title: const Text('Champ Select Begins'),
          value: options.champSelectBegins,
          groupValue: _option,
          dense: true,
          onChanged: (options value) {
            setState(() {
              _option = value;
            });
          },
        ),
        RadioListTile(
          title: const Text('Game Begins'),
          value: options.gameBegins,
          groupValue: _option,
          dense: true,
          onChanged: (options value) {
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
                    onChanged: (double value) {
                      setState(() {
                        _delay = value;
                      });
                    },
                  ),
                )
              ],
            ))
      ],
    );
  }
}
