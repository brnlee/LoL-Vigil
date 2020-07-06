import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class Resource<T> {
  final String url;
  T Function(Response response) parse;

  Resource({this.url, this.parse});
}

class Webservice {
  Future<T> load<T>(Resource<T> resource) async {
    print('GETTING ' + '${resource.url}');
    final response = await http.get(resource.url).timeout(Duration(seconds: 10));
    if (response.statusCode == 200) {
      print('OK');
      return resource.parse(response);
    } else {
      throw Exception('Failed to load data!');
    }
  }
}
