import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lolvigilmobile/models/leagues.dart';

class LeaguesDrawer extends StatefulWidget {
  LeaguesDrawer(this._leagues, Map<String, bool> leaguesToShow, this._onChanged) {
   _leaguesToShow = Map.from(leaguesToShow);
  }

  final List<League> _leagues;
  Map<String, bool> _leaguesToShow;
  final ValueChanged<Map<String, bool>> _onChanged;

  @override
  createState() => LeaguesDrawerState();
}

class LeaguesDrawerState extends State<LeaguesDrawer> {
  @override
  void dispose() {
    widget._onChanged(widget._leaguesToShow);
    super.dispose();
  }

  void _handleCheckBoxValueChange(String name) {
    setState(() {
      widget._leaguesToShow[name] = !widget._leaguesToShow[name];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
          children: <Widget>[
            Container(
              height: 80,
              alignment: Alignment.centerLeft,
              child: DrawerHeader(
                child: Text(
                  "Filter Displayed Leagues",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.all(0),
                  itemCount: widget._leagues.length,
                  itemBuilder: (context, index) {
                    return LeagueCheckBoxTile(
                        widget._leagues[index], widget._leaguesToShow[widget._leagues[index].name], _handleCheckBoxValueChange);
                  }),
            )
          ],
        ));
  }
}

//class LeaguesDrawer extends StatelessWidget {
//  LeaguesDrawer(this._leagues, this._leaguesToShow, this._onChanged);
//
//  final List<League> _leagues;
//  final Map<String, bool> _leaguesToShow;
//  final ValueChanged<Map<String, bool>> _onChanged;
//
//  void _handleCheckBoxValueChange(String name) {
//    print("Before ${_leaguesToShow[name]}");
//    _leaguesToShow[name] = !_leaguesToShow[name];
//    print("After ${_leaguesToShow[name]}");
////    _onChanged(_leaguesToShow);
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Drawer(
//        child: Column(
//      children: <Widget>[
//        Container(
//          height: 80,
//          alignment: Alignment.centerLeft,
//          child: DrawerHeader(
//            child: Text(
//              "Filter Displayed Leagues",
//              style: TextStyle(fontSize: 16),
//              textAlign: TextAlign.left,
//            ),
//          ),
//        ),
//        Expanded(
//          child: ListView.builder(
//              padding: EdgeInsets.all(0),
//              itemCount: _leagues.length,
//              itemBuilder: (context, index) {
//                return LeagueCheckBoxTile(
//                    _leagues[index], _leaguesToShow[_leagues[index].name], _handleCheckBoxValueChange);
//              }),
//        )
//      ],
//    ));
//  }
//}

class LeagueCheckBoxTile extends StatelessWidget {
  LeagueCheckBoxTile(this.league, this.isChecked, this.onChanged);

  final League league;
  final bool isChecked;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(league.name),
      secondary: CachedNetworkImage(
        placeholder: (context, url) => SizedBox(
          child: CircularProgressIndicator(),
          width: 30,
          height: 30,
        ),
        imageUrl: league.image,
        height: 30,
        fit: BoxFit.fitHeight,
      ),
      value: isChecked,
      onChanged: (bool value) {
        onChanged(league.name);
      },
    );
  }
}