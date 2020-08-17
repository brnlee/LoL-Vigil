import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/models/MatchAlarm.dart';
import 'package:lolvigilmobile/models/schedule.dart';
import 'package:lolvigilmobile/utils/constants.dart';
import 'package:lolvigilmobile/widgets/expandedAlarmOptions.dart';
import 'package:lolvigilmobile/widgets/matchSummary.dart';
import 'package:lolvigilmobile/widgets/teamTile.dart';
import 'package:expandable/expandable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class MatchListTile extends StatefulWidget {
  MatchListTile(this._event, {Key key}) : super(key: key);

  final Event _event;

  @override
  _MatchListTileState createState() => _MatchListTileState();
}

class _MatchListTileState extends State<MatchListTile> {
  MatchAlarm matchAlarm;
  Box alarmsBox;
  bool isPendingUpdate = false;

  @override
  void initState() {
    alarmsBox = Hive.box('MatchAlarms');
    setMatchAlarm(widget._event.match.id);
    super.initState();
  }

  @override
  void didUpdateWidget(MatchListTile oldWidget) {
    alarmsBox.listenable(keys: [matchAlarm.matchID]).removeListener(() {});
    setMatchAlarm(widget._event.match.id);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    alarmsBox.listenable(keys: [matchAlarm.matchID]).removeListener(() {});
    super.dispose();
  }

  void setMatchAlarm(String matchID) {
    String matchID = widget._event.match.id;
    if (!alarmsBox.containsKey(matchID)) {
      setState(() => matchAlarm = MatchAlarm(matchID, widget._event.match.strategy.count));
      alarmsBox.put(matchID, matchAlarm);
    } else
      setState(() => matchAlarm = alarmsBox.get(matchID));

    alarmsBox.listenable(keys: [matchID]).addListener(() {
      if (mounted && !isPendingUpdate) {
        setState(() => isPendingUpdate = true);
        Future.delayed(const Duration(seconds: 10), () {
          print(alarmsBox.get(matchID).toJson());
          makeSetAlarmRequest(alarmsBox.get(matchID));
          if (mounted) setState(() => isPendingUpdate = false);
        });
      }
    });
  }

  void makeSetAlarmRequest(MatchAlarm alarm) async {
    final http.Response response = await http.post(
      Constants.HOST + 'set_alarm',
      body: json.encode(alarm.toJson()),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode != 200) print('Failed to request an alarm with error ${response.statusCode}');
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
                                  matchAlarm.toggleMatchAlarm(val)
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
