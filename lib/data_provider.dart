

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_network_library/network_request_maker.dart';
import 'package:flutter_network_library/persistor.dart';
import 'package:hive_flutter/hive_flutter.dart';


typedef ResponseCallback(Response res);

class RESTExecutor{

  

  String method;
  String domain;
  String label;
  Map<String,String> params;
  List<String> identifiers;
  Map<String,String> headers;

  ResponseCallback successCallback;
  ResponseCallback errorCallback;

  Persistor cache;

  NetworkRequestMaker requestMaker;


  static Map<String,Map<String,Path>> domains;
  static Map<String,List<String>> domainState;

  static initialize(Map<String,dynamic> config,Map<String,Map<String,Path>> domains)async{

    RESTExecutor.domains = domains;

    await Persistor.initialize();
    await NetworkRequestMaker.initialize(config);

    domainState = {};
   domains.forEach((key, value) {
     domainState[key] = [];
   });
    
  }
  
  RESTExecutor(
    {
      @required this.domain,
      @required this.label,
      this.method = 'GET',
      this.params,
      this.identifiers = const [],
      this.headers,
      this.successCallback,
      this.errorCallback

    }
  ){
    requestMaker = NetworkRequestMaker();
    cache = Persistor(domain);

    cache.init(getKey());
  }

  void delete(){
    method = 'DELETE';
  }

  void post(){
    method = 'POST';
  }

  void setParams(Map<String,String> params){
        this.params = params??{};
  }

  void setHeaders(Map<String,String> headers){
    this.headers = headers;
  }

  getListenable(){
    return cache.getBox().listenable();
  }


  static refetchDomain(String domain){
    domainState[domain] = [];

    RESTExecutor(domain: domain,label: 'label').read();
  }

  Response read(){

    if(
      method=='GET'
      &&
      (!domainState[domain].contains(getKey()))
      ){

        domainState[domain].add(getKey());
        execute(force: true);
    }


    return cache.read(getKey());
  }


  String getKey(){
    
    return '$method$domain$label$identifiers$params$headers';
  }

  execute({
    Map<String,dynamic> data,

    bool force = false

  }) async{

    if(method == 'GET' && cache.getFreshStatus(getKey()) && !force ){

      if(successCallback!=null)
      successCallback(cache.read(getKey()));

      return;
    }

    cache.start(getKey());

    NetworkResponse response = await requestMaker.execute(

      path: domains[domain][label],
      query: params,
      identifiers: identifiers,
      data: data,
      method: method,
      headers: headers
    );


    // print(identifiers);
    // print(data);
    
    // print(response.data);
    if(response.statusCode>=400){

    // print('$domain - $label');
    
    // print(identifiers);
    // print(data);
    // print(response.data);
    }

    try{
      Map<String,dynamic> decoded = jsonDecode(response.data);

      
    await cache.complete(getKey(),
    success: response.success,
    rawData: response.data,
    data: decoded
    );
    }catch(e){
     await cache.complete(getKey(),
          success: response.success,
          rawData: response.data,
          data: {}
          );
    }

    if(successCallback!=null && response.success){

      successCallback(cache.read(getKey()));
    }

    else if(errorCallback!=null && !response.success)
      errorCallback(cache.read(getKey()));


    if(method?.toUpperCase()!='GET' && response.success){
      domainState[domain] = [];
    }

    if(
      method=='GET'
      &&
      false// response.isAuthError
      &&
      (domainState[domain].contains(getKey()))
      ){
        domainState[domain].remove(getKey());
      }


    await cache.end(getKey());
  }



}