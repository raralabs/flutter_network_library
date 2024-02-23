import 'package:flutter_network_library/authenticator.dart';
import 'package:flutter_network_library/flutter_network_library.dart';

enum NetworkScheme{
  http,
  https
}

class NetworkConfig{

  String? host;
  NetworkScheme? scheme;
  int? port;
  int cacheForSeconds;
  int timeoutSeconds;
  String? authDomain;
  String? loginLabel;
  String? registerLabel;
  bool clearCacheOnLogout;
  HeaderFormatter? authHeaderFormatter;
  AuthResponseFormatter? authResponseFormatter;

  NetworkConfig({
    this.authDomain,
    this.authHeaderFormatter,
    this.authResponseFormatter,
    this.host,
    this.port,
    this.loginLabel,
    this.registerLabel,
    this.scheme,
    this.clearCacheOnLogout = false,
    this.timeoutSeconds = 10,
    this.cacheForSeconds = 30
  });

}