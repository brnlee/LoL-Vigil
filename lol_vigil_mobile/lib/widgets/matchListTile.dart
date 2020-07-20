import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';
import 'package:lolvigilmobile/models/schedule.dart';
import 'package:lolvigilmobile/widgets/expandedAlarmOptions.dart';
import 'package:lolvigilmobile/widgets/matchSummary.dart';
import 'package:lolvigilmobile/widgets/teamTile.dart';
import 'package:expandable/expandable.dart';

class MatchListTile extends StatefulWidget {
  MatchListTile(this._event, {Key key}) : super(key: key);

  final Event _event;

  @override
  _MatchListTileState createState() => _MatchListTileState();
}

class _MatchListTileState extends State<MatchListTile> {
  MatchAlarm matchAlarm;
  Box alarmsBox;

  @override
  void initState() {
    alarmsBox = Hive.box('MatchAlarms');
    String matchID = widget._event.match.id;
    if (!alarmsBox.containsKey(matchID)) {
      matchAlarm = MatchAlarm(matchID, widget._event.match.strategy.count);
      alarmsBox.put(matchID, matchAlarm);
      print('Added new alarm for ${widget._event.match}');
    } else {
      matchAlarm = alarmsBox.get(matchID);
      print('Retrieved from box:  ${widget._event.match}');
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Event event = widget._event;
    return ExpandableNotifier(
      child: ScrollOnExpand(
        child: Column(
          children: <Widget>[
            ExpandablePanel(
              theme: const ExpandableThemeData(hasIcon: false),
              header: Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: MatchSummary(event),
                      flex: 1,
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[TeamTile(event.match.teams[0]), TeamTile(event.match.teams[1])],
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        Switch(
                            value: matchAlarm.isOn,
                            onChanged: (bool val) => {
                                  setState(() => {matchAlarm.isOn = val}),
                                  alarmsBox.put(matchAlarm.matchID, matchAlarm)
                                }),
                        ExpandableIcon(
                          theme: ExpandableThemeData(
                            iconColor: Theme.of(context).hintColor,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              expanded: ExpandedAlarmOptions(matchAlarm),
            ),
            Divider()
          ],
        ),
      ),
    );
  }
}
