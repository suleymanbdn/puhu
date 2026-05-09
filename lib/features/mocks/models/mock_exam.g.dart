// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_exam.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MockExamAdapter extends TypeAdapter<MockExam> {
  @override
  final int typeId = 12;

  @override
  MockExam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MockExam(
      id: fields[0] as String,
      publisher: fields[1] as String,
      date: fields[2] as DateTime,
      examType: fields[3] as ExamType,
      subjectNets: (fields[4] as Map).cast<String, double>(),
      note: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MockExam obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.publisher)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.examType)
      ..writeByte(4)
      ..write(obj.subjectNets)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
