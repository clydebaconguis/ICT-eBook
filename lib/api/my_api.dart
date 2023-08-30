// import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CallApi {
  final String _ckIpv4 = 'https://app.cklms.ph/';
  final String _domain = 'https://app.cklms.ph/api/';

  // final String _ckIpv4 = 'https://lms.smsaccess.net/';
  // final String _domain = 'https://lms.smsaccess.net/api/';

  // final String _ckIpv4 = 'http://192.168.0.105:8000/';
  // final String _domain = 'http://192.168.0.105:8000/api/';
  getHost() {
    // var domain = await _loadSavedDomainName();
    // return '$domain/';
    return _ckIpv4;
  }

  getDomain() {
    return _domain;
  }

  postData(data, apiUrl) async {
    // var fullUrl = _ckIpv4 + apiUrl;
    // return await http.post(Uri.parse(fullUrl),
    //     body: jsonEncode(data), headers: _setHeaders());
  }

  // login(data, apiUrl) async {
  //   // var domain = await _loadSavedDomainName();
  //   // if (domain.isNotEmpty) {
  //   //   var fullUrl = '$domain/api/$apiUrl';
  //   //   return await http.post(Uri.parse(fullUrl),
  //   //       body: jsonEncode(data), headers: _setHeaders());
  //   // }
  //   var fullUrl = '$_domain$apiUrl';
  //   return await http.post(
  //     Uri.parse(fullUrl),
  //     body: jsonEncode(data),
  //   );
  // }

  login(data, apiUrl) async {
    // var token = await getToken();
    // var fullUrl =
    //     '$_domain$apiUrl?email=${data['email']}&password=${data['password']}';
    var fullUrl = '$_domain$apiUrl';
    return await http.post(Uri.parse(fullUrl), body: data);
  }

  // getData(apiUrl) async {
  //   var fullUrl = _ckIpv4 + apiUrl + await _getToken();
  //   return await http.get(Uri.parse(fullUrl), headers: _setHeaders());
  // }

  // _setHeaders() => {
  //       'Content-type': 'application/json',
  //       'Accept': 'application/json',
  //     };

  getToken() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token');
    return '?token=$token';
  }

  getPublicData(apiUrl) async {
    // var domain = await _loadSavedDomainName();
    // var fullUrl = '$domain/api/$apiUrl';
    var fullUrl = '$_domain$apiUrl';
    return await http.get(Uri.parse(fullUrl));
  }
}
