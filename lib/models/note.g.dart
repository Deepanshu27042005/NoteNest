// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      subject: fields[2] as String,
      tags: (fields[3] as List).cast<String>(),
      filePath: fields[4] as String,
      fileType: fields[5] as String,
      createdAt: fields[6] as DateTime,
      pageCount: fields[7] as int,
      thumbnailPath: fields[8] as String?,
      extractedText: fields[9] as String?,
      aiSummary: fields[10] as String?,
      aiKeyPoints: (fields[11] as List?)?.cast<String>(),
      aiFormulas: (fields[12] as List?)?.cast<String>(),
      aiKeywords: (fields[13] as List?)?.cast<String>(),
      aiDefinitions: (fields[14] as List?)?.cast<String>(),
      aiGeneratedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.fileType)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.pageCount)
      ..writeByte(8)
      ..write(obj.thumbnailPath)
      ..writeByte(9)
      ..write(obj.extractedText)
      ..writeByte(10)
      ..write(obj.aiSummary)
      ..writeByte(11)
      ..write(obj.aiKeyPoints)
      ..writeByte(12)
      ..write(obj.aiFormulas)
      ..writeByte(13)
      ..write(obj.aiKeywords)
      ..writeByte(14)
      ..write(obj.aiDefinitions)
      ..writeByte(15)
      ..write(obj.aiGeneratedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
