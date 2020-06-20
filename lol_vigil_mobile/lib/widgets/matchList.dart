import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/models.dart';
import 'package:lolvigilmobile/services/webservice.dart';
import 'matchListTile.dart';

class MatchListState extends State<MatchList> {
  List<Event> _events = List<Event>();
  Map<String, Alarm> _alarms = Map<String, Alarm>();

  @override
  void initState() {
    super.initState();
    _populateEvents();
  }

  void _populateEvents() {
    Webservice().load(Schedule.all).then((events) {
      setState(() => {_events = events, _alarms = _setAlarms(events)});
    });
  }

  Map<String, Alarm> _setAlarms(List<Event> events) {
    print('Setting Alarms');
    return Map.fromIterable(
        events.map((event) => _alarms[event.match.id] ?? Alarm(event.match.id)),
        key: (alarm) => alarm.matchID,
        value: (alarm) => alarm);
  }

  MatchListTile _buildItemsForListView(BuildContext context, int index) {
    return MatchListTile(_events[index], _alarms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Games'),
        ),
        body: _events.length != 0
            ? RefreshIndicator(
                child: ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: _buildItemsForListView,
                ),
                onRefresh: () async => _populateEvents(),
              )
            : Center(child: CircularProgressIndicator()));
  }
}

class MatchList extends StatefulWidget {
  @override
  createState() => MatchListState();
}
