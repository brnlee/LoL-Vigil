import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/models/leagues.dart';
import 'package:lolvigilmobile/models/schedule.dart';
import 'package:lolvigilmobile/services/webservice.dart';
import 'package:lolvigilmobile/widgets/leaguesDrawer.dart';
import 'matchListTile.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class MatchListState extends State<MatchList> with WidgetsBindingObserver {
  int _nextPage = 1;
  List<Event> _events = List<Event>();
  List<League> _leagues = List<League>();
  Set<String> _leaguesToShow = Set();
  Map<String, Alarm> _alarms = Map<String, Alarm>();
  DateTime _lastMatchDateTime;
  ScrollController _scrollController = ScrollController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _populateEvents();
    _populateLeagues();

//    _scrollController.addListener(() {
//      if (_scrollController.position.maxScrollExtent <= _scrollController.position.pixels) {
//        _populateEvents();
//      }
//    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _populateLeagues() {
    Webservice().load(LeaguesResponse.all).then((leagues) {
      setState(() => {_leagues = leagues});
    });
  }

  void _populateEvents([int requestedPage]) {
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
    return Map.fromIterable(events.map((event) => _alarms[event.match.id] ?? Alarm(event.match.id)),
        key: (alarm) => alarm.matchID, value: (alarm) => alarm);
  }

  Widget _buildItemsForListView(BuildContext context, int index, List<Event> events) {
    if (index == events.length) {
      _populateEvents();
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

  Widget _buildProgressIndicator() {

    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new CircularProgressIndicator(),
      ),
    );
  }

  Set<String> getFilteredLeagueValues() {
    Box leaguesBox = Hive.box('Leagues');
    return Set.from(leaguesBox.keys.where((league) => leaguesBox.get(league, defaultValue: true)));
  }

  updateFilteredLeagues() async {
    print("updating filtered leagues");
    Set<String> leaguesToShow = getFilteredLeagueValues();
    if (SetEquality().equals(_leaguesToShow, leaguesToShow)) return;

    setState(() {
      isLoading = true;
    });

    Future.delayed(
        Duration(seconds: 1),
        () => setState(() {
              isLoading = false;
              _leaguesToShow = leaguesToShow;
            }));
  }

  @override
  Widget build(BuildContext context) {
    print('NEXT PAGE $_nextPage');
    List<Event> filteredEvents = _events.length > 0 && _leaguesToShow.length > 0
        ? _events.where((e) => _leaguesToShow.contains(e.tournament.name)).toList()
        : _events;

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
                    if (hasFocus && !isLoading) updateFilteredLeagues();
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
                      )
                    ],
                  )),
              onRefresh: () async => _populateEvents(1),
            )
          : _buildProgressIndicator(),
      drawer: LeaguesDrawer(_leagues, Hive.box('Leagues')),
    );
  }
}

class MatchList extends StatefulWidget {
  @override
  createState() => MatchListState();
}
