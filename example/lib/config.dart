import 'package:flutter_network_library/config.dart';
import 'package:flutter_network_library/domain.dart';

var config = NetworkConfig(
  scheme: NetworkScheme.http,
  host:  '65.1.81.123',
  port: 8080
);

var domains = {
  'appState': Domain(
    type: DomainType.basic,

    path: {
      'theme':(_)=>'/change-theme'
    }
  ),

  'api':Domain(
    cacheForSeconds: 5,
    path: {
      'list':(_)=>'/api'
    }
  )
};