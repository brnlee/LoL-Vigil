import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/schedule.dart';

class MatchSummary extends StatelessWidget {
  MatchSummary(this.event);

  final Event event;

  @override
  Widget build(BuildContext context) {
    int hour = event.startTime.toLocal().hour;
    String period = 'AM';
    if (hour >= 12) {
      hour = hour > 12 ? hour - 12 : hour;
      period = 'PM';
    } else if (hour == 0) hour = 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 5),
                child: Text(
                  hour.toString(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Text(period),
            ],
            crossAxisAlignment: CrossAxisAlignment.end,
          ),
        ),
        Text(
          event.tournament.name,
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        ),
        Text(
          event.blockName,
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        )
      ],
    );
  }
}
