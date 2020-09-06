import 'dart:convert';
// import 'dart:io';
import 'package:flutter_network_library/authenticator.dart';
import 'package:http/http.dart' as http;
typedef String Path(List<String> identifiers);

class NetworkResponse{

  int statusCode;
  bool success;
  String data;

  NetworkResponse({
    this.statusCode,
    this.data,
    this.success = false
  });

  static NetworkResponse ok(String data){
    return NetworkResponse(
      data:data,
      success: true,
      statusCode: 200
    );
  }

  static NetworkResponse valError(String data){
    return NetworkResponse(
      data:data,
      success: false,
      statusCode: 400
    );
  }

  static NetworkResponse authError(String data){
    return NetworkResponse(
      data: data,
      success: false,
      statusCode: 401
    );
  }

static NetworkResponse netError(){
    return NetworkResponse(
      data:json.encode({'error_message': 'Connection failed'}),
      success: false,
      statusCode: 600
    );
  }

  static NetworkResponse notFoundError(){
    return NetworkResponse(
      data:json.encode({'error_message': 'not found'}),
      success: false,
      statusCode: 404
    );
  }

  
bool get isAuthError => statusCode==401;
bool get isNetworkError => statusCode==600;
}

class NetworkRequestMaker {
 
  static String url = 'api.moru.com.np';
  static int timeout = 30000;
  static int cacheForSeconds = 0;
  static String scheme = 'https';
  static String auth = '/login';
  static String refreshUrl = '/refresh-token';

  static Authenticator authenticator;
  
  String finalPath = '';
  Path path;

  String data;
  Map<String, dynamic> meta = {};

  bool fetching = false;

  static bool refreshing;

 

  static Future<void> initialize(Map<String, dynamic> config) async {
    NetworkRequestMaker.url = config['host'];
    NetworkRequestMaker.scheme = config['scheme'];
    NetworkRequestMaker.timeout = config['timeout'];
    NetworkRequestMaker.authenticator = Authenticator(
      domain: config['authDomain'],
      label: config['authLabel'],
      dependentDomains: ['me','feed','activities','artists','venues']
    );
    return;
  }


   Future<NetworkResponse> execute({
    Map<String,dynamic> data = const {},

    Map<String, String> query = const {},
    List<String> identifiers = const [],

    Path path,

    String method,

    Map<String,String> headers
  }) async {


    String token = authenticator.getAccessToken();

     http.Client _client = http.Client();

    Uri finalUrl;
    if (scheme == 'https')
      finalUrl = Uri.https(url, (path != null) ? path(identifiers) : '', query);
    else
      finalUrl = Uri.http(url, (path != null) ? path(identifiers) : '', query);


    http.Request request;

    var time = DateTime.now();

    try {
      //  request = await _client.openUrl(this.method, finalUrl).timeout(_client.connectionTimeout);
      request = http.Request(method, finalUrl);
      // await _client.send(request);

    } catch (e) {
      // if (this.errorCallback != null && this.state.mounted)
      //   this.errorCallback(json.encode({'error_message': 'Connection failed'}));
      return NetworkResponse.netError();
    }
    request.headers['Content-Type'] = 'application/json';

  if(token!=null)
   request.headers['Authorization'] = 'Bearer ' +
            (token??'');

    if (data != null && method != 'GET') request.body = json.encode(data);

    request.headers.addAll(headers??{});

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {

      // if (this.errorCallback != null && this.state.mounted)
      //   this.errorCallback(json.encode({'error_message': 'Connection failed'}));

      return NetworkResponse.netError();
    }

    // print(DateTime.now().difference(time).inMilliseconds);

    String responseString = '';
    // response.transform(utf8.decoder).listen((responseData){
    //   responseString+=responseData;
    // },


    responseString = await response.stream.transform(utf8.decoder).join();


     if (response.statusCode == 200) {

        return NetworkResponse.ok(responseString);
     }

     else if(response.statusCode == 404){
       return NetworkResponse.notFoundError();
     }

     else if(response.statusCode == 401 || response.statusCode == 422 || response.statusCode == 403){
      
      if(!(refreshing??false)){
        refreshing=true;
      authenticator.refresh();

      }

     return NetworkResponse.authError(responseString);
     }

     return NetworkResponse.valError(responseString);

    response.stream.transform(utf8.decoder).listen((responseData) {
      responseString += responseData;
    }, onDone: () async {
      if (response.statusCode == 200) {

        return NetworkResponse.ok(responseString);
       
        // await domain.write(method + finalPath, responseString);

        // if (successCallback != null && state.mounted)
        //   this.successCallback(responseString);
      } else if (response.statusCode == 401) {
      
        // if (await refresh()) {
        //   print('token renewed');
        //   execute(data: data, query: query, id: id, force: force);
        // } else {
        //   await logout();
        //   if (state.mounted) {
        //     Navigator.pushNamedAndRemoveUntil(
        //       state.context,
        //       '/',
        //       (route) => false,
        //     );
        //   }
        // }

      } 
      // else if (errorCallback != null && state.mounted) {
      //   String errorString = responseString;
      //   try {
      //     var error = jsonDecode(responseString)['error_message'];
      //   } catch (e) {
      //     errorString =
      //         jsonEncode({'error_message': jsonDecode(responseString)});
      //   } finally {
      //     this.errorCallback(responseString);
      //   }
      // }
      // if (state?.mounted ?? false) state.setState(() {});
      
    });
  }

}
