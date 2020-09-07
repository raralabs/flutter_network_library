import 'package:flutter_network_library/authenticator.dart';

enum NetworkScheme{
  http,
  https
}

class NetworkConfig{

  String host;
  NetworkScheme scheme;

  String authDomain;
  String loginLabel;
  String registerLabel;

  HeaderFormatter authHeaderFormatter;

}