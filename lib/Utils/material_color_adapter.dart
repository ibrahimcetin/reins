import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

class MaterialColorAdapter extends TypeAdapter<MaterialColor> {
  @override
  final typeId = 0;

  @override
  MaterialColor read(BinaryReader reader) {
    final value = reader.readInt();
    return Colors.primaries.firstWhere(
      (color) => color.value == value,
      orElse: () => Colors.grey,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialColor obj) {
    writer.writeInt(obj.value);
  }
}
