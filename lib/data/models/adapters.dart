import 'package:flutter/material.dart'; // <--- THIS WAS MISSING
import 'package:hive/hive.dart';
import 'package:note_app/data/models/note.dart';
import 'package:note_app/data/models/user_profile.dart';

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      deltaJson: fields[3] as String?,
      tags: (fields[4] as List).cast<String>(),
      category: fields[5] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      color: Color(
        fields[7] as int,
      ), // Now works because of the material import
      imageUrl: fields[8] as String?,
      isPinned: fields[9] as bool,
      isLocked: fields[10] as bool,
      isBookmarked: fields[11] as bool,
      isChecklist: fields[12] as bool,
      checklistItems: (fields[13] as List?)?.cast<ChecklistItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.deltaJson)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.date.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.color.value)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.isPinned)
      ..writeByte(10)
      ..write(obj.isLocked)
      ..writeByte(11)
      ..write(obj.isBookmarked)
      ..writeByte(12)
      ..write(obj.isChecklist)
      ..writeByte(13)
      ..write(obj.checklistItems);
  }
}

class ChecklistItemAdapter extends TypeAdapter<ChecklistItem> {
  @override
  final int typeId = 1;

  @override
  ChecklistItem read(BinaryReader reader) {
    return ChecklistItem(text: reader.readString(), isDone: reader.readBool());
  }

  @override
  void write(BinaryWriter writer, ChecklistItem obj) {
    writer.writeString(obj.text);
    writer.writeBool(obj.isDone);
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile(
      name: reader.readString(),
      seed: reader.readString(),
      presetId: reader.readString(),
      backgroundColor: reader.readString(),
      radius: reader.readDouble(),
      scale: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.seed);
    writer.writeString(obj.presetId);
    writer.writeString(obj.backgroundColor ?? '#F3F4F6');
    writer.writeDouble(obj.radius);
    writer.writeDouble(obj.scale);
  }
}
