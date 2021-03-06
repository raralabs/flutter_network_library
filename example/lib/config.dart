import 'package:flutter_network_library/config.dart';
import 'package:flutter_network_library/domain.dart';

var config = NetworkConfig(
  scheme: NetworkScheme.https,
  host:  'api2.binance.com',
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
      'list':(_)=>'/market'
    }
  )
};