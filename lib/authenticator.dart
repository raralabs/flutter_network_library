


import 'package:flutter_network_library/data_provider.dart';
import 'package:flutter_network_library/flutter_network_library.dart';

typedef Map<String,String> HeaderFormatter(String accessToken);

class Authenticator extends RESTExecutor{

  String refreshLabel;

  List<String> dependentDomains;

  HeaderFormatter authHeaderFormatter;

  Authenticator({
    ResponseCallback successCallback,
    ResponseCallback errorCallback,

    this.dependentDomains = const [],
    
    this.refreshLabel = 'refresh',
    String domain = 'auth',
    String label = 'login',

    this.authHeaderFormatter

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

  Map<String,String> getAuthorizationHeader(){

    if(!isLoggedIn())
    return {};

    if(authHeaderFormatter!=null)
    return authHeaderFormatter(getAccessToken());

    return {
      'Authorization': 'Bearer ${getAccessToken()}'
    };

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