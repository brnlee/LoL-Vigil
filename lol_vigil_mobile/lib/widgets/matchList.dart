import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/leagues.dart';
import 'package:lolvigilmobile/models/schedule.dart';
import 'package:lolvigilmobile/services/webservice.dart';
import 'package:lolvigilmobile/widgets/leaguesDrawer.dart';
import 'matchListTile.dart';
import 'package:intl/intl.dart';

class MatchListState extends State<MatchList> with WidgetsBindingObserver {
  List<Event> _events = List<Event>();
  Map<String, Alarm> _alarms = Map<String, Alarm>();
  DateTime _lastMatchDateTime;
  int _nextPage = 1;
  ScrollController _scrollController = ScrollController();
  List<League> _leagues = List<League>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _populateEvents();
    _populateLeagues();

    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent ==
          _scrollController.position.pixels) {
        _populateEvents();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _populateLeagues() {
    Webservice().load(LeaguesResponse.all).then((leagues) {
      setState(() => {
            _leagues = leagues,
          });
    });
  }

  void _populateEvents([int requestedPage]) {
    int page = requestedPage ?? _nextPage;
    if (page == -1) return;
    Webservice().load(Schedule.get(page)).then((schedule) {
      setState(() => {
            _events = page == 1 ? schedule.events : _events + schedule.events,
            _alarms = _setAlarms(_events),
            _nextPage = schedule.hasNextPage ? page + 1 : -1
          });
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
    if (index == _events.length) {
      return _buildProgressIndicator();
    } else if (index == 0) {
      _lastMatchDateTime = null;
    }
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

  _scrollToTop() {
    setState(() => {_events = List<Event>()});
//    _scrollController
//        .animateTo(_scrollController.position.minScrollExtent,
//            duration: Duration(milliseconds: 500), curve: Curves.easein)
//        .then((_) => _populateEvents(1));
    _populateEvents(1);
  }

  @override
  Widget build(BuildContext context) {
    print('BUILDING...\nNEXT PAGE $_nextPage');

    return Scaffold(
      appBar: AppBar(
        title: Text('Games'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _scrollToTop(),
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => null,
          )
        ],
      ),
      body: _events.length != 0
          ? RefreshIndicator(
              child: ListView.builder(
                controller: _scrollController,
                // Add 1 for progress indicator
                itemCount:
                    _nextPage == -1 ? _events.length : _events.length + 1,
                itemBuilder: _buildItemsForListView,
              ),
              onRefresh: () async => _populateEvents(1),
            )
          : Center(child: CircularProgressIndicator()),
      drawer: LeaguesDrawer(_leagues),
    );
  }
}

class MatchList extends StatefulWidget {
  @override
  createState() => MatchListState();
}

Widget _buildProgressIndicator() {
  return new Padding(
    padding: const EdgeInsets.all(8.0),
    child: new Center(
      child: new Opacity(
        opacity: 1.0,
        child: new CircularProgressIndicator(),
      ),
    ),
  );
}
