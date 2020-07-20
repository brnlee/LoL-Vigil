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
    Hive.close();
    super.dispose();
  }

  void _populateLeagues() {
    Webservice().load(LeaguesResponse.all).then((leagues) {
      Box leaguesBox = Hive.box('Leagues');
      leagues.forEach((league) {
        if (!leaguesBox.containsKey(league.name)) leaguesBox.put(league.name, true);
      });
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

  Widget _buildItemsForListView(BuildContext context, int index, List dateSeperatedEvents) {
    if (index == dateSeperatedEvents.length) {
      _populateEvents();
      return _buildProgressIndicator();
    } else if (dateSeperatedEvents[index] is String) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 0, 5),
          child: Text(
            dateSeperatedEvents[index],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Divider(),
      ]);
    } else
      return MatchListTile(dateSeperatedEvents[index]);
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
    print('FILTERING LEAGUES');
    Set<String> leaguesToShow = getFilteredLeagueValues();
    if (SetEquality().equals(_leaguesToShow, leaguesToShow)) return;
    print(leaguesToShow);

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

    List dateSeperatedEvents = [];
    DateTime prevEventTime;
    _events.forEach((event) {
      if (_leaguesToShow.contains(event.tournament.name)) {
        DateTime time = event.startTime.toLocal();
        if (prevEventTime == null || prevEventTime.day != time.day)
          dateSeperatedEvents.add(DateFormat('EEEE - LLLL d').format(time));
        dateSeperatedEvents.add(event);
        prevEventTime = time;
      }
    });

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
          ),
          IconButton(
            icon: Icon(Icons.alarm),
            onPressed: () => {print("CLEARING ALARMS"), Hive.box('matchAlarms').clear()},
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
                          itemCount: _nextPage == -1 ? dateSeperatedEvents.length : dateSeperatedEvents.length + 1,
                          itemBuilder: (context, index) => _buildItemsForListView(context, index, dateSeperatedEvents),
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
