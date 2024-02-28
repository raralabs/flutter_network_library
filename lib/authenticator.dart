import 'package:flutter_network_library/constants.dart';
import 'package:flutter_network_library/flutter_network_library.dart';

typedef Map<String, String> HeaderFormatter(String? accessToken);
typedef AuthTokenObject AuthResponseFormatter(Map<String, dynamic>? data);

class AuthTokenObject {
  String? accessToken;
  String? refreshToken;

  AuthTokenObject({this.accessToken, this.refreshToken});
}

class Authenticator extends RESTExecutor {
  String? refreshLabel;

  List<String> dependentDomains;
  bool clearCacheOnLogout;
  HeaderFormatter? authHeaderFormatter;
  AuthResponseFormatter? authResponseFormatter;

  Authenticator({
    ResponseCallback? successCallback,
    ResponseCallback? errorCallback,
    this.dependentDomains = const [],
    this.refreshLabel = 'refresh',
    String domain = 'auth',
    String? label = 'login',
    this.clearCacheOnLogout = false,
    this.authHeaderFormatter,
    this.authResponseFormatter,
  }) : super(
            domain: domain,
            label: label,
            method: 'POST',
            successCallback: successCallback,
            errorCallback: errorCallback);

  login(Map<String, dynamic> data) {
    super.execute(data: data);
  }

  Future<Response> refresh() async {
    NetworkRequestMaker.refreshing = true;
    try {
      var response = await RESTExecutor(
              domain: super.domain,
              method: 'POST',
              label: refreshLabel,
              headers: {'Authorization': 'Bearer ${getPrimaryRefreshToken()}'},
              successCallback: (res) {
                super.cache.write(super.getKey(), res);
              },
              errorCallback: (_) {
                // logout();
              })
          .execute(data: {});

      NetworkRequestMaker.refreshing = false;

      return response;
    } catch (e) {
      NetworkRequestMaker.refreshing = false;
      return Response(statusCode: 404);
    }
  }

  Future<void> logout() async {
    RESTExecutor.domainState.updateAll((key, value) => {});

    for (var domain in dependentDomains) {
      await Persistor(domain).deleteAll();
    }

    await super.cache.delete(super.getKey());

    if (clearCacheOnLogout) {
      return RESTExecutor.clearCache();
    }
  }

  Map<String, String> getPrimaryAuthorizationHeader() {
    if (!isLoggedIn()) return {};

    if (authHeaderFormatter != null)
      return authHeaderFormatter!(getPrimaryAccessToken());

    return {'Authorization': 'Bearer ${getPrimaryAccessToken()}'};
  }

  Map<String, String> getSecondaryAuthorizationHeader() {
    if (!isLoggedIn()) return {};

    if (authHeaderFormatter != null)
      return authHeaderFormatter!(getSecondaryAccessToken());

    return {'Authorization': 'Bearer ${getSecondaryAccessToken()}'};
  }

  String? getPrimaryAccessToken() {
    Response result =
        Persistor(Constants.tokenBoxName).read(Constants.primaryToken);

    if (result.success == false) return null;

    if (authResponseFormatter != null)
      return authResponseFormatter!(result.data).accessToken;

    return result.data['access_token'];
  }

  String? getPrimaryRefreshToken() {
    Response result =
        Persistor(Constants.tokenBoxName).read(Constants.primaryToken);

    if (result.success == false) return null;

    if (authResponseFormatter != null)
      return authResponseFormatter!(result.data).refreshToken;

    return result.data['refresh_token'];
  }

  String? getSecondaryAccessToken() {
    Response result =
        Persistor(Constants.tokenBoxName).read(Constants.secondaryToken);

    if (result.success == false) return null;

    if (authResponseFormatter != null)
      return authResponseFormatter!(result.data).accessToken;

    return result.data['access_token'];
  }

  String? getSecondaryRefreshToken() {
    Response result =
        Persistor(Constants.tokenBoxName).read(Constants.secondaryToken);

    if (result.success == false) return null;

    if (authResponseFormatter != null)
      return authResponseFormatter!(result.data).refreshToken;

    return result.data['refresh_token'];
  }

  bool isLoggedIn() {
    return (getPrimaryAccessToken() != null);
  }
}
