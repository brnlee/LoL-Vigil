import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/models.dart';
import 'package:lolvigilmobile/services/webservice.dart';

class MatchListState extends State<MatchList> {
  List<Event> _events = List<Event>();

  @override
  void initState() {
    super.initState();
    _populateEvents();
  }

  void _populateEvents() {
    Webservice().load(Schedule.all).then((events) =>
    {
      setState(() =>
      {
        _events = events
      })
    });
  }

  ListTile _buildItemsForListView(BuildContext context, int index) {
    final String match = _events[index].match.teams[0].code + ' vs ' +  _events[index].match.teams[1].code;
    return ListTile(
      title: Text(match),
      subtitle: Text(_events[index].league.name)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Games'),
      ),
      body: ListView.builder(
        itemCount: _events.length,
        itemBuilder: _buildItemsForListView,
      ),
    );
  }
}

class MatchList extends StatefulWidget {
  @override
  createState() => MatchListState();
}