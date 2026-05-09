// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExamProfileAdapter extends TypeAdapter<ExamProfile> {
  @override
  final int typeId = 10;

  @override
  ExamProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExamProfile(
      examType: fields[0] as ExamType,
      targetUniversity: fields[1] as String?,
      targetDepartment: fields[2] as String?,
      targetNet: fields[3] as double?,
      examDate: fields[4] as DateTime,
      dailyTargetHours: fields[5] as double,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExamProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.examType)
      ..writeByte(1)
      ..write(obj.targetUniversity)
      ..writeByte(2)
      ..write(obj.targetDepartment)
      ..writeByte(3)
      ..write(obj.targetNet)
      ..writeByte(4)
      ..write(obj.examDate)
      ..writeByte(5)
      ..write(obj.dailyTargetHours)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExamTypeAdapter extends TypeAdapter<ExamType> {
  @override
  final int typeId = 9;

  @override
  ExamType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExamType.tyt;
      case 1:
        return ExamType.sayisal;
      case 2:
        return ExamType.esitAgirlik;
      case 3:
        return ExamType.sozel;
      case 4:
        return ExamType.dil;
      default:
        return ExamType.tyt;
    }
  }

  @override
  void write(BinaryWriter writer, ExamType obj) {
    switch (obj) {
      case ExamType.tyt:
        writer.writeByte(0);
        break;
      case ExamType.sayisal:
        writer.writeByte(1);
        break;
      case ExamType.esitAgirlik:
        writer.writeByte(2);
        break;
      case ExamType.sozel:
        writer.writeByte(3);
        break;
      case ExamType.dil:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
