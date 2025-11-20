// 2020-02-15

import 'package:http/http.dart' as http;
import 'dart:convert';
import './pm_dartUtils.dart';
import './pm_constants.dart';

const kpmStatus = 'status';
const kqlError = 'error';
const kpmPayload = 'payload';
const kpmOK = 'OK';

class PMAjax {
  final PMR p = PMR(className: 'AJAX', defaultLevel: 0);

  String baseUrl;

  PMAjax(this.baseUrl) {
    //p.logR('AJAX service created for: $baseUrl');
  }

  static String urlEncode(String sin) {
    String sout = '';
    for (int i = 0; i < sin.length; i++) {
      int c = sin.codeUnitAt(i);
      int j = pmListFind(kpmUrlEncodings, c, xform: (x) => x[0]);
      if (j  < 0) {
        sout = sout + String.fromCharCode(c);
      } else {
        sout = sout + kpmUrlEncodings[j][1];
      }
    }
    return sout;
  }

  dynamic _sendData(action, {String? verb, List? params}) async {
    //p.logR('Ajax - verb: $verb, params: $params');
    String fullUrl = baseUrl + (verb != null ? '/' + verb : '');
    // params come in form [ [param_name, param_data], ...]
    if (pmNotNil(params)) {
      fullUrl = fullUrl + '?';
      for (int i = 0; i < params!.length; i++) {
        if (i > 0) fullUrl = fullUrl + '&';
        fullUrl = fullUrl + params[i][0] + '=' + urlEncode(params[i][1]);
      }
    }
    //p.logR('Calling Server: $baseUrl',);
    http.Response response = await action(Uri.parse(fullUrl));
    if (response.statusCode == 200) {
      // data = response.body;
      var data = jsonDecode(response.body);
      //p.logR('Ajax return OK: $data');
      return data;
    } else {
      p.logE("Ajax Error: ${response.statusCode}");
      return {
        kpmStatus: kqlError,
        kpmPayload: 'Ajax error, code: ${response.statusCode}'
      };
    }
  }

  dynamic post({String? verb, List? params}) async {
    return await _sendData(http.post, verb: verb, params: params);
  }

  dynamic get({String? verb, List? params}) async {
    return await _sendData(http.get, verb: verb, params: params);
  }
}
