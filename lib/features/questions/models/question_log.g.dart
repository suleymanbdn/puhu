// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionLogAdapter extends TypeAdapter<QuestionLog> {
  @override
  final int typeId = 11;

  @override
  QuestionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionLog(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      topicId: fields[2] as String?,
      correct: fields[3] as int,
      wrong: fields[4] as int,
      blank: fields[5] as int,
      date: fields[6] as DateTime,
      note: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.topicId)
      ..writeByte(3)
      ..write(obj.correct)
      ..writeByte(4)
      ..write(obj.wrong)
      ..writeByte(5)
      ..write(obj.blank)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
