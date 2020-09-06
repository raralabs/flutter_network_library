


import 'package:flutter_network_library/data_provider.dart';
import 'package:flutter_network_library/flutter_network_library.dart';

class Authenticator extends RESTExecutor{

  String refreshLabel;

  List<String> dependentDomains;

  Authenticator({
    ResponseCallback successCallback,
    ResponseCallback errorCallback,

    this.dependentDomains = const [],
    
    this.refreshLabel = 'refresh',
    String domain = 'auth',
    String label = 'login'

  })
  :
  super(
    domain: domain,
    label: label,
    method:'POST',
    successCallback: successCallback,
    errorCallback: errorCallback

  );

  login(Map<String,dynamic> data){
    super.execute(
      data: data
    );
  }

  refresh()async{

    await RESTExecutor(
      domain: super.domain,
      method: 'POST',
      label: refreshLabel,
      headers: {
        'Authorization': getRefreshToken()
      },
      successCallback: (res){
        super.cache.write(super.getKey(), res);
      },
      errorCallback: (_){
        // logout();
      }
    ).execute();

    NetworkRequestMaker.refreshing = false;
  }

  Future<void> logout()async{
    
    for (var domain in dependentDomains) {
      await Persistor(domain).deleteAll();
    }
    
    await super.cache.delete(super.getKey());
  }

  String getAccessToken(){

    Response result = super.cache.read(super.getKey());

    if(result == null)
    return null;

    if(result.success == false)
    return null;

    return result.parseDetail()['access_token'];
      
  }

  String getRefreshToken(){

    Response result = super.cache.read(super.getKey());

    if(result == null)
    return null;

    if(result.success == false)
    return null;

    return result.parseDetail()['refresh_token'];
      
  }

  bool isLoggedIn(){

    return (getAccessToken()!=null);

  }
}