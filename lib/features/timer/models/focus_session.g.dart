// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusSessionAdapter extends TypeAdapter<FocusSession> {
  @override
  final int typeId = 5;

  @override
  FocusSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusSession(
      id: fields[0] as String,
      type: fields[1] as FocusType,
      plannedMinutes: fields[2] as int,
      actualMinutes: fields[3] as int,
      mood: fields[4] as FocusMood?,
      startTime: fields[5] as DateTime,
      endTime: fields[6] as DateTime?,
      taskId: fields[7] as String?,
      categoryName: fields[8] as String?,
      note: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FocusSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.plannedMinutes)
      ..writeByte(3)
      ..write(obj.actualMinutes)
      ..writeByte(4)
      ..write(obj.mood)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.taskId)
      ..writeByte(8)
      ..write(obj.categoryName)
      ..writeByte(9)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FocusMoodAdapter extends TypeAdapter<FocusMood> {
  @override
  final int typeId = 3;

  @override
  FocusMood read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FocusMood.happy;
      case 1:
        return FocusMood.neutral;
      case 2:
        return FocusMood.stressed;
      default:
        return FocusMood.happy;
    }
  }

  @override
  void write(BinaryWriter writer, FocusMood obj) {
    switch (obj) {
      case FocusMood.happy:
        writer.writeByte(0);
        break;
      case FocusMood.neutral:
        writer.writeByte(1);
        break;
      case FocusMood.stressed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusMoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FocusTypeAdapter extends TypeAdapter<FocusType> {
  @override
  final int typeId = 4;

  @override
  FocusType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FocusType.work;
      case 1:
        return FocusType.shortBreak;
      case 2:
        return FocusType.longBreak;
      default:
        return FocusType.work;
    }
  }

  @override
  void write(BinaryWriter writer, FocusType obj) {
    switch (obj) {
      case FocusType.work:
        writer.writeByte(0);
        break;
      case FocusType.shortBreak:
        writer.writeByte(1);
        break;
      case FocusType.longBreak:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
