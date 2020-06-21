import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/models.dart';
import 'package:lolvigilmobile/widgets/matchSummary.dart';
import 'package:lolvigilmobile/widgets/teamTile.dart';

class MatchListTile extends StatefulWidget {
  MatchListTile(this._event, this._alarms, {Key key}) : super(key: key);

  final Event _event;
  final Map<String, Alarm> _alarms;

  @override
  _MatchListTileState createState() => _MatchListTileState();
}

class _MatchListTileState extends State<MatchListTile> {
  @override
  Widget build(BuildContext context) {
    Event event = widget._event;
    return InkWell(
      child: Column(
        children: <Widget>[
          Padding(
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
                    children: <Widget>[
                      TeamTile(event.match.teams[0]),
                      TeamTile(event.match.teams[1])
                    ],
                  ),
                ),
                Switch(
                    value: widget._alarms[event.match.id].isSet,
                    onChanged: (bool val) => {
                          setState(() =>
                              {widget._alarms[event.match.id].isSet = val})
                        })
              ],
            ),
          ),
          Divider(
            height: 0,
          )
        ],
      ),
      onTap: () => {},
    );
  }
}
