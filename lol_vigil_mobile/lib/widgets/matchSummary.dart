import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/models.dart';

class MatchSummary extends StatelessWidget {
  MatchSummary(this.event);

  final Event event;

  @override
  Widget build(BuildContext context) {
    int hour = event.startTime.toLocal().hour;
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
                  (hour <= 12 ? hour : hour % 12).toString(),
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Text(hour < 12 ? 'AM' : 'PM'),
            ],
            crossAxisAlignment: CrossAxisAlignment.end,
          ),
        ),
        Text(
          event.league.name,
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        ),
        Text(
          'BO${event.match.strategy.count}',
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        )
      ],
    );
  }
}