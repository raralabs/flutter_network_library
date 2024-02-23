import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_network_library/data_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
part 'persistor.g.dart';

@HiveType(typeId: 0)
class Response extends HiveObject {
  @HiveField(0)
  String? rawData;

  @HiveField(1)
  DateTime? timeStamp;

  @HiveField(2)
  Map<String, dynamic> data;

  @HiveField(3)
  Map<String, dynamic> error;

  @HiveField(4)
  bool fetching;

  @HiveField(5)
  bool success;

  @HiveField(6)
  int statusCode;

  Response({
    this.success = false,
    this.fetching = false,
    this.data = const {},
    this.error = const {},
    this.statusCode = 200,
  });

  List<Map<String, dynamic>> parseList() {
    try {
      List<Map<String, dynamic>> list = List.from(data['data'] ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      return list;
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> parseDetail() {
    try {
      Map<String, dynamic> detail =
          Map<String, dynamic>.from(data['data'] ?? {});

      return detail;
    } catch (e) {
      return {};
    }
  }

  getValidationErrorFor(String key) {
    try {
      return error['validation_errors'][key][0];
    } catch (e) {
      return null;
    }
  }

  value(String key) {
    try {
      return data[key];
    } catch (e) {
      return null;
    }
  }
}

class Persistor {
  Box? box;
  static bool initialized = false;

  static Future<void> initialize({String databaseName = 'store3.db'}) async {
    var dir = await getTemporaryDirectory();
    Hive.init(dir.path);

    if (!kIsWeb) await Hive.initFlutter();

    Hive.registerAdapter(ResponseAdapter());

    for (var key in RESTExecutor.domains.keys) {
      var box = await Hive.openBox(key);

      for (var key in box.keys) {
        Response result = box.get(key, defaultValue: Response());

        result.fetching = false;
        result.error = {};

        await box.put(key, result);
      }
    }

    initialized = true;
  }

  static Future<void> clear() async {
    for (var key in RESTExecutor.domains.keys) {
      var box = await Hive.openBox(key);

      await box.clear();
    }
  }

  Persistor(String domain) {
    box = Hive.box(domain);
  }

  Box? getBox() {
    return box;
  }

  bool getFreshStatus(String key, int cacheSeconds, int retrySeconds) {
    Response result = read(key);

    if (result == null || cacheSeconds == null) return false;

    if (result.success == false && retrySeconds != null)
      return (result.timeStamp ?? DateTime.now())
          .isAfter(DateTime.now().subtract(Duration(seconds: retrySeconds)));

    return (result.success) &&
        (result.timeStamp ?? DateTime.now())
            .isAfter(DateTime.now().subtract(Duration(seconds: cacheSeconds)));
  }

  init(String key) {
    Response result = box!.get(key, defaultValue: Response());

    result.fetching = false;
    result.error = {};

    write(key, result);
  }

  start(String key) {
    Response result = box!.get(key, defaultValue: Response());

    result.fetching = true;
    result.error = {};

    write(key, result);
  }

  Future<void> end(String key) async {
    Response result = box!.get(key, defaultValue: Response());

    result.fetching = false;

    await write(key, result);
  }

  Future<void> complete(String key,
      {bool? success,
      Map<String, dynamic>? data,
      String? rawData,
      int? statusCode}) async {
    Response result = box!.get(key, defaultValue: Response());
    result.success = success ?? false;

    if (success ?? false) {
      result.data = data ?? {};
      result.error = {};
    } else
      result.error = (data as Map).cast<String, dynamic>();

    if (statusCode != null) {
      result.statusCode = statusCode;
    }
    result.timeStamp = DateTime.now();
    result.rawData = rawData;

    await write(key, result);
  }

  write(String key, Response value) async {
    await box!.put(key, value);
  }

  Response read(String key) {
    Response result = box!.get(key, defaultValue: Response());

    if (result.data != null && !(result.data is List))
      result.data = (result.data).cast<String, dynamic>();

    return result;
  }

  Future<void> delete(String key) async {
    return box!.delete(key);
  }

  Future<int> deleteAll() async {
    return box!.clear();
  }
}
