import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/models.dart';
import 'package:lolvigilmobile/services/webservice.dart';
import 'matchListTile.dart';
import 'package:intl/intl.dart';

class MatchListState extends State<MatchList> {
  List<Event> _events = List<Event>();
  Map<String, Alarm> _alarms = Map<String, Alarm>();
  DateTime _lastMatchDateTime;

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

  Widget _buildItemsForListView(BuildContext context, int index) {
    if (index == 0) _lastMatchDateTime = null;
    DateTime time = _events[index].startTime.toLocal();
    Widget matchTile = MatchListTile(_events[index], _alarms);
    if (_lastMatchDateTime == null || _lastMatchDateTime.day != time.day) {
      String formattedDate = DateFormat('EEEE - LLLL dd').format(time);
      matchTile = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 0, 5),
            child: Text(
              formattedDate,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(),
          matchTile
        ],
      );
    }
    _lastMatchDateTime = time;
    return matchTile;
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
          : Center(child: CircularProgressIndicator()),
      drawer: Drawer(),
    );
  }
}

class MatchList extends StatefulWidget {
  @override
  createState() => MatchListState();
}
