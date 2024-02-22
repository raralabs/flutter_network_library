// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persistor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResponseAdapter extends TypeAdapter<Response> {
  @override
  final int typeId = 0;

  @override
  Response read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Response(
      success: fields[5] as bool,
      fetching: fields[4] as bool,
      data: (fields[2] as Map).cast<String, dynamic>(),
      error: (fields[3] as Map).cast<String, dynamic>(),
      statusCode: fields[6] as int,
    )
      ..rawData = fields[0] as String?
      ..timeStamp = fields[1] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, Response obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.rawData)
      ..writeByte(1)
      ..write(obj.timeStamp)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.error)
      ..writeByte(4)
      ..write(obj.fetching)
      ..writeByte(5)
      ..write(obj.success)
      ..writeByte(6)
      ..write(obj.statusCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
