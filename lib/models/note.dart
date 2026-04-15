import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String subject;

  @HiveField(3)
  List<String> tags;

  @HiveField(4)
  final String filePath;

  @HiveField(5)
  final String fileType; // 'pdf' or 'image'

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  int pageCount;

  @HiveField(8)
  String? thumbnailPath;

  // --- NEW FIELDS FOR SMART REVISION ---

  @HiveField(9)
  String? extractedText;

  @HiveField(10)
  String? aiSummary;

  @HiveField(11)
  List<String>? aiKeyPoints;

  @HiveField(12)
  List<String>? aiFormulas;

  @HiveField(13)
  List<String>? aiKeywords;

  @HiveField(14)
  List<String>? aiDefinitions;

  @HiveField(15)
  DateTime? aiGeneratedAt;

  Note({
    required this.id,
    required this.title,
    required this.subject,
    required this.tags,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
    this.pageCount = 1,
    this.thumbnailPath,
    this.extractedText,
    this.aiSummary,
    this.aiKeyPoints,
    this.aiFormulas,
    this.aiKeywords,
    this.aiDefinitions,
    this.aiGeneratedAt,
  });
}
