import 'package:flutter_network_library/authenticator.dart';
import 'package:flutter_network_library/flutter_network_library.dart';

enum NetworkScheme{
  http,
  https
}

class NetworkConfig{

  String host;
  NetworkScheme scheme;

  int cacheForSeconds;

  String authDomain;
  String loginLabel;
  String registerLabel;

  HeaderFormatter authHeaderFormatter;
  AuthResponseFormatter authResponseFormatter;

  NetworkConfig({
    this.authDomain,
    this.authHeaderFormatter,
    this.authResponseFormatter,
    this.host,
    this.loginLabel,
    this.registerLabel,
    this.scheme,
    this.cacheForSeconds = 30
  });

}