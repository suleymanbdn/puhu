// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeBudgetAdapter extends TypeAdapter<TimeBudget> {
  @override
  final int typeId = 6;

  @override
  TimeBudget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeBudget(
      id: fields[0] as String,
      categoryName: fields[1] as String,
      targetMinutesPerWeek: fields[2] as int,
      spentMinutes: fields[3] as int,
      weekStartDate: fields[4] as DateTime,
      customColor: fields[5] as Color?,
      customIcon: fields[6] as IconData?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeBudget obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryName)
      ..writeByte(2)
      ..write(obj.targetMinutesPerWeek)
      ..writeByte(3)
      ..write(obj.spentMinutes)
      ..writeByte(4)
      ..write(obj.weekStartDate)
      ..writeByte(5)
      ..write(obj.customColor)
      ..writeByte(6)
      ..write(obj.customIcon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeBudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
