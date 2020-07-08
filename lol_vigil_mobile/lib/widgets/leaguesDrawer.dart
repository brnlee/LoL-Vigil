import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lolvigilmobile/models/leagues.dart';

class LeaguesDrawer extends StatelessWidget {
  LeaguesDrawer(this._leagues, this._leaguesToShow, this._onChanged);

  final List<League> _leagues;
  final Map<String, bool> _leaguesToShow;
  final ValueChanged<Map<String, bool>> _onChanged;

  void _handleCheckBoxValueChange(String name) {
    _leaguesToShow[name] = !_leaguesToShow[name];
    _onChanged(_leaguesToShow);
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
                return LeagueCheckBoxTile(
                    _leagues[index], _leaguesToShow[_leagues[index].name], _handleCheckBoxValueChange);
              }),
        )
      ],
    ));
  }
}

class LeagueCheckBoxTile extends StatefulWidget {
  LeagueCheckBoxTile(this.league, this.isChecked, this.onChanged);

  final League league;
  final bool isChecked;
  final ValueChanged<String> onChanged;

  @override
  createState() => LeagueCheckBoxTileState();
}

class LeagueCheckBoxTileState extends State<LeagueCheckBoxTile> {
  bool isChecked = true;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.league.name),
      secondary: CachedNetworkImage(
        placeholder: (context, url) => SizedBox(
          child: CircularProgressIndicator(),
          width: 30,
          height: 30,
        ),
        imageUrl: widget.league.image,
        height: 30,
        fit: BoxFit.fitHeight,
      ),
      value: widget.isChecked,
      onChanged: (bool value) {
        widget.onChanged(widget.league.name);
        setState(() {
          isChecked = !isChecked;
        });
      },
    );
  }
}
