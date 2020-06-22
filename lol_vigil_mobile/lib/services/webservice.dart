import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class Resource<T> {
  final String url;
  T Function(Response response) parse;

  Resource({this.url, this.parse});
}

class Webservice {
  Future<T> load<T>(Resource<T> resource, int page) async {
    print('GETTING ' + '${resource.url}?page=$page');
//    try {
    final response = await http.get('${resource.url}?page=$page').timeout(Duration(seconds: 5));
    if (response.statusCode == 200) {
      print('OK');
      return resource.parse(response);
    } else {
      throw Exception('Failed to load data!');
    }
//    } on TimeoutException catch (e) {
//      print(e);
//    } on SocketException catch (e) {
  }
}
