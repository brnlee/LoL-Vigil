import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lolvigilmobile/models/leagues.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LeaguesDrawer extends StatelessWidget {
  LeaguesDrawer(this._leagues, this._leaguesBox);

  final List<League> _leagues;
  final Box _leaguesBox;

  void _handleCheckBoxValueChange(String name, bool newValue) {
    _leaguesBox.put(name, newValue);
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
                  itemCount: _leagues.length,
                  itemBuilder: (context, index) {
                    League league = _leagues[index];
                    return ValueListenableBuilder(
                        valueListenable: _leaguesBox.listenable(),
                        builder: (context, box, widget) => LeagueCheckBoxTile(
                            league, _leaguesBox.get(league.name, defaultValue: true), _handleCheckBoxValueChange));
                  }),
            )
          ],
        ));
  }
}

class LeagueCheckBoxTile extends StatelessWidget {
  LeagueCheckBoxTile(this.league, this.isChecked, this.onChanged);

  final League league;
  final bool isChecked;
  final Function onChanged;

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
        onChanged(league.name, value);
      },
    );
  }
}
