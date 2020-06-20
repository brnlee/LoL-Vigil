import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/models.dart';
import 'package:lolvigilmobile/widgets/TeamTile.dart';

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
    return InkWell(
      child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        TeamTile(widget._event.match.teams[0]),
                        TeamTile(widget._event.match.teams[1])
                      ],
                    ),
                  ),
                  Switch(
                      value: widget._alarms[widget._event.match.id].isSet,
                      onChanged: (bool val) => {
                            setState(() => {
                                  widget._alarms[widget._event.match.id].isSet =
                                      val
                                })
                          })
                ],
              ),
              Divider(
                height: 0,
              )
            ],
          )),
      onTap: () => {},
    );
  }
}
