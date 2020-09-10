

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_network_library/config.dart';
import 'package:flutter_network_library/domain.dart';
import 'package:flutter_network_library/network_request_maker.dart';
import 'package:flutter_network_library/persistor.dart';
import 'package:hive_flutter/hive_flutter.dart';


typedef ResponseCallback(Response res);

class ResponseListenableWidget extends ValueListenableBuilder{

  ResponseListenableWidget({
    Listenable valueListenable,
    Widget child
  }): super(valueListenable:valueListenable,builder:(_,__,___)=>child);
}

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


  static Map<String,Domain> domains;
  static Map<String,Set<String>> domainState;

  static int cacheForSeconds = 60;

  static initialize(NetworkConfig config,Map<String,Domain> domains)async{

    RESTExecutor.domains = domains;

    if(config.cacheForSeconds!=null)
    RESTExecutor.cacheForSeconds = config.cacheForSeconds;

    await Persistor.initialize();
    await NetworkRequestMaker.initialize(config);

    domainState = {};
   domains.forEach((key, value) {
     domainState[key] = {};
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

  Widget widget({Widget child})=>ResponseListenableWidget(
    valueListenable: getListenable(),
    child: child,
  );

  getListenable(){
    return cache.getBox().listenable();
  }


  static refetchDomain(String domain){
    domainState[domain] = {};

    RESTExecutor(domain: domain,label: 'label').read();
  }

  Response get response => read();

  Response read(){

    if(

      domains[domain].type==DomainType.network
      &&
      method=='GET'
      &&
      !cache.read(getKey()).fetching
      &&
      (
      (!domainState[domain].contains(getKey()))
      
      ||

      (!cache.getFreshStatus(getKey(), domains[domain].cacheForSeconds??RESTExecutor.cacheForSeconds))
      )
      ){

        domainState[domain].add(getKey());
        execute();
    }
    return cache.read(getKey());
  }


  String getKey(){
    
    return '$method$domain$label$identifiers$params$headers';
  }

  execute({
    Map<String,dynamic> data

  }) async{
    switch(domains[domain].type){

      case DomainType.network:
      await networkExecute(data);
      break;

      default:
      await basicExecute(data);
      break;

    }
  }

  basicExecute(Map<String,dynamic> data)async{

    if(data == null)
    await cache.end(getKey());
    else
    await cache.complete(getKey(), data: data, success: true);

    if(successCallback!=null && response.success){
      successCallback(cache.read(getKey()));
    }
  }

  networkExecute(Map<String,dynamic> data)async{
    
    cache.start(getKey());

    NetworkResponse response = await requestMaker.execute(

      path: domains[domain].path[label],
      query: params,
      identifiers: identifiers,
      data: data,
      method: method,
      headers: headers
    );

    if(response.statusCode>=400){
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
      domainState[domain] = {};
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