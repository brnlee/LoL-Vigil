import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/leagues.dart';
import 'package:lolvigilmobile/models/schedule.dart';
import 'package:lolvigilmobile/services/webservice.dart';
import 'package:lolvigilmobile/widgets/leaguesDrawer.dart';
import 'matchListTile.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class MatchListState extends State<MatchList> with WidgetsBindingObserver {
  List<Event> _events = List<Event>();
  Map<String, Alarm> _alarms = Map<String, Alarm>();
  DateTime _lastMatchDateTime;
  int _nextPage = 1;
  ScrollController _scrollController = ScrollController();
  List<League> _leagues = List<League>();
  Map<String, bool> _leaguesToShow = Map();
  bool isLoading = false;
  List<Event> _filteredEvents;

  @override
  void initState() {
    super.initState();
    _populateEvents();
    _populateLeagues();

    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent <= _scrollController.position.pixels) {
//        _populateEvents();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _populateLeagues() {
    print("POPULATE LEAGUES");
    Webservice().load(LeaguesResponse.all).then((leagues) {
      setState(() => {
            _leagues = leagues,
            _leaguesToShow = {for (var l in leagues) l.name: true}
          });
    });
  }

  void _populateEvents([int requestedPage]) {
    print("POPULATING EVENTS");
    int page = requestedPage ?? _nextPage;
    if (page == -1) return;
    Webservice().load(Schedule.get(page)).then((schedule) {
      setState(() => {
            if (page == 1) _events = schedule.events else _events.addAll(schedule.events),
            _alarms = _setAlarms(_events),
            _nextPage = schedule.hasNextPage ? page + 1 : -1,
          });
    });
  }

  Map<String, Alarm> _setAlarms(List<Event> events) {
    print('Setting Alarms');
    return Map.fromIterable(events.map((event) => _alarms[event.match.id] ?? Alarm(event.match.id)),
        key: (alarm) => alarm.matchID, value: (alarm) => alarm);
  }

  Widget _buildItemsForListView(BuildContext context, int index, List<Event> events) {
    if (index == events.length) {
      _populateEvents(_nextPage);
      return _buildProgressIndicator();
    } else if (index == 0) _lastMatchDateTime = null;

    DateTime time = events[index].startTime.toLocal();
    bool show = _lastMatchDateTime == null || _lastMatchDateTime.day != time.day;
    _lastMatchDateTime = time;

    if (show) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 0, 5),
            child: Text(
              DateFormat('EEEE - LLLL dd').format(time),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(),
          MatchListTile(events[index], _alarms)
        ],
      );
    }

    return MatchListTile(events[index], _alarms);
  }

  void _scrollToTop() {
    setState(() => {_events = List<Event>()});
    _populateEvents(1);
  }

  void _handleLeagueFilterChange(Map<String, bool> newLeaguesToShow) {
    if (!MapEquality().equals(_leaguesToShow, newLeaguesToShow)) {
      _leaguesToShow = newLeaguesToShow;
      isLoading = true;
    }
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

  Future<List<Event>> filterEvents() async {
    return Future(() => _events.length > 0 && _leaguesToShow != null
        ? _events.where((e) => _leaguesToShow[e.tournament.name] ?? true).toList()
        : _events);
  }

  setIsLoading() async {
    setState(() {
      isLoading = true;
    });
    Future.delayed(
        Duration(seconds: 1),
        () => filterEvents().then((events) => {
              setState(() {
                isLoading = false;
                _filteredEvents = events;
              })
            }));
  }

  @override
  Widget build(BuildContext context) {
    print('BUILDING...\nNEXT PAGE $_nextPage');
    List<Event> filteredEvents = _filteredEvents ??
        (_events.length > 0 && _leaguesToShow != null
            ? _events.where((e) => _leaguesToShow[e.tournament.name] ?? true).toList()
            : _events);
    _filteredEvents = null;
//    setState(() {
//      isLoading = false;
//    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Games"),
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
              child: Focus(
                  autofocus: true,
                  onFocusChange: (hasFocus) {
                    if (hasFocus && isLoading) setIsLoading();
                  },
                  child: Stack(
                    children: <Widget>[
                      Opacity(
                        opacity: isLoading ? 1.0 : 0.0,
                        child: Center(
                          child: _buildProgressIndicator(),
                        ),
                      ),
                      Opacity(
                        opacity: isLoading ? 0.0 : 1.0,
                        child: ListView.builder(
                          cacheExtent: 2.0,
                          controller: _scrollController,
                          // Add 1 for progress indicator
                          itemCount: _nextPage == -1 ? filteredEvents.length : filteredEvents.length + 1,
                          itemBuilder: (context, index) => _buildItemsForListView(context, index, filteredEvents),
                        ),
                      ),
                    ],
                  )),
              onRefresh: () async => _populateEvents(1),
            )
          : Center(child: CircularProgressIndicator()),
      drawer: LeaguesDrawer(_leagues, _leaguesToShow, _handleLeagueFilterChange),
    );
  }
}

class MatchList extends StatefulWidget {
  @override
  createState() => MatchListState();
}
