
import 'package:flutter_network_library/flutter_network_library.dart';

enum DomainType{
  network,
  basic
}

class Domain{

  int? cacheForSeconds;
  int? retryAfterSeconds;
  DomainType type;

  Map<String,Path>? path;

  Domain({
    this.path,
    this.cacheForSeconds,
    this.type = DomainType.network
  });
  

}