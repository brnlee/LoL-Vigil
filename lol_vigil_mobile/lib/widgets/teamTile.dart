import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lolvigilmobile/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lolvigilmobile/utils/constants.dart';

class TeamTile extends StatelessWidget {
  TeamTile(this.team);

  final Team team;

  @override
  Widget build(BuildContext context) {
    Uri imageUri = Uri.http(
        Constants.AKAMAI_URL, '/image', {'resize': '50:', 'f': team.image});
    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
          child: CachedNetworkImage(
            placeholder: (context, url) => SizedBox(
              child: CircularProgressIndicator(),
              width: 35,
              height: 35,
            ),
            imageUrl: imageUri.toString(),
            height: 35,
            fit: BoxFit.fitHeight,
          ),
        ),
        Text(
          team.code,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}
