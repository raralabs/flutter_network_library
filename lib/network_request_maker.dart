import 'dart:convert';
// import 'dart:io';
import 'package:flutter_network_library/authenticator.dart';
import 'package:flutter_network_library/config.dart';
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

  static NetworkResponse ok(String data,[int statusCode = 200]){
    return NetworkResponse(
      data:data,
      success: true,
      statusCode: statusCode
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

  static NetworkResponse notFoundError([String data]){
    return NetworkResponse(
      data:data??json.encode({'error_message': 'not found'}),
      success: false,
      statusCode: 404
    );
  }

  
bool get isAuthError => statusCode==401;
bool get isNetworkError => statusCode==600;
}

class NetworkRequestMaker {
 
  static String host;
  static int port;
  static String scheme = 'https';

  static int timeoutSeconds;


  static Authenticator authenticator;
  
  String finalPath = '';
  Path path;

  String data;
  Map<String, dynamic> meta = {};

  bool fetching = false;

  static bool refreshing;

 

  static Future<void> initialize(NetworkConfig config) async {
    NetworkRequestMaker.host = config.host;
    NetworkRequestMaker.port = config.port;
    NetworkRequestMaker.scheme = config.scheme==NetworkScheme.http?'http':'https';

    assert(config.timeoutSeconds != null);
    
    NetworkRequestMaker.timeoutSeconds = config.timeoutSeconds;
    
    if(config.authDomain!=null)
    NetworkRequestMaker.authenticator = Authenticator(
      domain: config.authDomain,
      label: config.loginLabel,
      refreshLabel: config.registerLabel,
      clearCacheOnLogout: config.clearCacheOnLogout,
      authHeaderFormatter: config.authHeaderFormatter,
      authResponseFormatter: config.authResponseFormatter
    );
    return;
  }


   Future<NetworkResponse> execute({
    Map<String,dynamic> data = const {},

    Map<String, dynamic> query = const {},
    List<String> identifiers = const [],

    Path path,

    String method,

    Map<String,String> headers
  }) async {

     http.Client _client = http.Client();

    Uri finalUrl;

    finalUrl = Uri(host:host,
    port: port,
     scheme: scheme, path: (path != null) ? path(identifiers) : '',queryParameters: query);
  

    http.Request request;

    try {
      request = http.Request(method, finalUrl);

    } catch (e) {
      return NetworkResponse.netError();
    }
    request.headers['Content-Type'] = 'application/json';

    request.headers.addAll(authenticator?.getAuthorizationHeader()??{});

    if (data != null && method != 'GET') request.body = json.encode(data);

    request.headers.addAll(headers??{});

    http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(Duration(seconds: NetworkRequestMaker.timeoutSeconds));
    } catch (e) {

      return NetworkResponse.netError();
    }

    String responseString = '';

    responseString = await response.stream.transform(utf8.decoder).join();


     if (response.statusCode == 200 || response.statusCode == 201) {

        return NetworkResponse.ok(responseString,response.statusCode);
     }

     else if(response.statusCode == 404){
       return NetworkResponse.notFoundError(responseString);
     }

     else if(response.statusCode == 401 || response.statusCode == 422 || response.statusCode == 403){
      
      if(!(refreshing??false)){
        refreshing=true;
      authenticator?.refresh();

      }

     return NetworkResponse.authError(responseString);
     }

     return NetworkResponse.valError(responseString);

  }

}
